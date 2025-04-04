import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final List<String> supportedContentType = ["html", "svg", "mermaid"];

class HtmlContentWidget extends StatefulWidget {
  final String content;
  final String contentType;
  final double? width;
  final double? height;
  final String mermaidTheme;
  final Widget? loadingWidget;
  final Duration loadingTimeout;
  final Function()? onLoadComplete;
  final Function(String)? onLoadError;

  const HtmlContentWidget({
    Key? key,
    required this.content,
    required this.contentType,
    this.width = 400,
    this.height = 300,
    this.mermaidTheme = 'default',
    this.loadingWidget,
    this.loadingTimeout = const Duration(seconds: 30),
    this.onLoadComplete,
    this.onLoadError,
  }) : super(key: key);

  @override
  _HtmlContentWidgetState createState() => _HtmlContentWidgetState();
}

class _HtmlContentWidgetState extends State<HtmlContentWidget> {
  bool _isLoading = true;

  late double effectiveWidth;
  late double effectiveHeight;

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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        effectiveWidth = widget.width?.clamp(0.0, constraints.maxWidth) ??
            constraints.maxWidth.clamp(0.0, 1000.0);
        effectiveHeight = widget.height?.clamp(0.0, constraints.maxHeight) ??
            constraints.maxHeight.clamp(0.0, 800.0);

        return Stack(
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
                  ),
                  // mimeType: 'text/html',
                  encoding: 'utf8',
                ),
                initialSettings: InAppWebViewSettings(
                  accessibilityIgnoresInvertColors: false,
                  supportZoom: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _generateHtmlContent(
  String content,
  String contentType, {
  String mermaidTheme = "default",
  double? effectiveWidth,
  double? effectiveHeight,
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
              // background-color: #f0f0f0;
            }
            .content-wrapper {
              width: 100%;
              height: 100%;
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

  if (contentType == "mermaid") {
    return '''
        $baseHtml
        <script src="/assets/assets/mermaid.min.js"></script>
        <script>
          document.addEventListener("DOMContentLoaded", function() {
            try {
              mermaid.initialize({
                startOnLoad: true,
                theme: '${mermaidTheme}',
                securityLevel: 'loose'
              });
              mermaid.init(undefined, '.mermaid');
            } catch (error) {
              notifyParent('error:' + error.message);
            }
          });
        </script>
        </head>
        <body>
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
                svgElement.style.backgroundColor = '#ffffff';
              }
            } catch (error) {
              notifyParent('error:' + error.message);
            }
          });
        </script>
        </head>
        <body>
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
        <body>
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
