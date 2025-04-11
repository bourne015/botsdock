import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final List<String> supportedContentType = ["html", "svg", "mermaid"];

class HtmlContentWidget extends StatefulWidget {
  final String content;
  final String contentType;
  final double? width;
  final double? height;
  final String mermaidTheme;

  const HtmlContentWidget({
    Key? key,
    required this.content,
    required this.contentType,
    this.width = 400,
    this.height = 300,
    this.mermaidTheme = 'default',
  }) : super(key: key);

  @override
  _HtmlContentWidgetState createState() => _HtmlContentWidgetState();
}

class _HtmlContentWidgetState extends State<HtmlContentWidget> {
  late double effectiveWidth;
  late double effectiveHeight;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        effectiveWidth = widget.width?.clamp(0.0, constraints.maxWidth) ??
            constraints.maxWidth.clamp(0.0, 1000.0);
        effectiveHeight = widget.height?.clamp(0.0, constraints.maxHeight) ??
            constraints.maxHeight.clamp(0.0, 800.0);

        return Stack(
          alignment: AlignmentDirectional.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 400),
              width: effectiveWidth,
              height: effectiveHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _generateHtmlContent(
                    widget.content,
                    widget.contentType,
                    effectiveWidth: effectiveWidth,
                    effectiveHeight: effectiveHeight,
                    isDarkMode: isDarkMode,
                  ),
                  // mimeType: 'text/html',
                  encoding: 'utf8',
                ),
                initialSettings: InAppWebViewSettings(
                  accessibilityIgnoresInvertColors: false,
                  supportZoom: true,
                ),
                onLoadStart: (controller, url) {
                  Logger.info("WebView load start");
                },
                onWebViewCreated: (controller) {
                  Logger.info("WebView created");
                  _loadingStatus(true);
                },
                onLoadStop: (controller, url) {
                  // Future.delayed(Duration(milliseconds: 200), () {
                  _loadingStatus(false);
                  // });
                  Logger.info("WebView loaded");
                },
                onReceivedError: (controller, req, message) {
                  Logger.info("WebView load error: ${message.description}");
                  _loadingStatus(false);
                },
                onConsoleMessage: (controller, consoleMessage) {
                  Logger.info("WebView Console: ${consoleMessage.message}");
                },
              ),
            ),
            if (widget.contentType == "mermaid" && _isLoading)
              _loadingContent(),
          ],
        );
      },
    );
  }

  void _loadingStatus(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  Widget _loadingContent() {
    return Container(
      // padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent, //Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(strokeWidth: 4.0),
          SizedBox(height: 10),
          Text('Loading...', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

String _generateHtmlContent(
  String content,
  String contentType, {
  String mermaidTheme = "default",
  double? effectiveWidth,
  double? effectiveHeight,
  bool isDarkMode = false,
}) {
  final baseHtml = '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              margin: 0;
              padding: 0;
              // display: flex;
              justify-content: center;
              align-items: center;
              background-color: var(--background-color); /* 使用 CSS 变量 */
              color: var(--text-color);
            }
            /* 定义浅色模式和深色模式的 CSS 变量 */
            :root {
              --background-color: #FAFBFB; /* 浅色模式背景 */
              --text-color: #000000; /* 浅色模式文字 */
            }

            /* 深色模式 */
            body.dark-mode {
              --background-color: #292a2f; /* 深色模式背景 */
              --text-color: #ffffff; /* 深色模式文字 */
            }

            .content-wrapper {
              width: 90%;
              height: 90%;
              // display: flex;
              justify-content: center;
              align-items: center;
              opacity: 0;
              transition: opacity 0.3s ease-in-out;
            }
            .content-wrapper.loaded {
              opacity: 1;
            }
            svg {
              max-width: $effectiveWidth;
              max-height: $effectiveHeight;
              height: auto;
              width: auto;
            }
          </style>
          <script>
            function notifyParent(message) {
              window.parent.postMessage(message, '*');
            }

            window.addEventListener('load', function() {
              document.querySelector('.content-wrapper').classList.add('loaded');
              notifyParent('loaded');
            });

            window.addEventListener('error', function(event) {
              notifyParent('error:' + event.message);
            });
          </script>
    ''';
  final bodyClass = isDarkMode ? 'dark-mode' : '';
  if (contentType == "mermaid") {
    return '''
        $baseHtml
        <script src="https://unpkg.zhimg.com/mermaid@11.6.0/dist/mermaid.min.js"></script>
        <script>
          document.addEventListener("DOMContentLoaded", function() {
            try {
              console.log("Initializing mermaid...");
              mermaid.initialize({
                startOnLoad: true,
                theme: '${mermaidTheme}',
                securityLevel: 'loose'
              });
              mermaid.init(undefined, '.mermaid').then(function() {
                console.log("Mermaid rendering complete");
                notifyParent('loaded');
              }).catch(function(error) {
                console.error("Mermaid rendering error:", error);
                notifyParent('error:' + error.message);
              });
            } catch (error) {
              console.error("Mermaid error:" + error);
              notifyParent('error:' + error.message);
            }
          });
        </script>
        </head>
        <body  class="$bodyClass">
          <div class="content-wrapper">
            <div class="mermaid">
              ${_sanitizeHtml(content, contentType)}
            </div>
          </div>
        </body>
      </html>
      ''';
  } else if (contentType == "svg") {
    return '''
        $baseHtml
        <script>
          document.addEventListener("DOMContentLoaded", function() {
            try {
              const svgElement = document.querySelector('svg');
              if (svgElement) {
                svgElement.style.backgroundColor = 'transparent';
              }
            } catch (error) {
              notifyParent('error:' + error.message);
            }
          });
        </script>
        </head>
        <body  class="$bodyClass">
          <div class="content-wrapper">
            ${_sanitizeHtml(content, contentType)}
          </div>
        </body>
      </html>
      ''';
  } else {
    return '''
        $baseHtml
        </head>
        <body  class="$bodyClass">
          <div class="content-wrapper">
            ${_sanitizeHtml(content, contentType)}
          </div>
        </body>
      </html>
      ''';
  }
}

String _sanitizeHtml(String html, String contentType) {
  final pattern = r'^```(?:mermaid|svg|html)?\s*([\s\S]*?)\s*```$';
  final regExp = RegExp(pattern, caseSensitive: false, multiLine: true);

  final match = regExp.firstMatch(html);
  if (match != null && match.groupCount >= 1) {
    html = match.group(1) ?? '';
  }

  if (contentType == "svg" && !html.trim().toLowerCase().startsWith('<svg')) {
    return '<svg xmlns="http://www.w3.org/2000/svg">${html}</svg>';
  }
  return html;
}
