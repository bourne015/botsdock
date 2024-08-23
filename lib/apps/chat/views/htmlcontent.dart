import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;
import 'dart:js_util' as js;

enum ContentType { html, mermaid }

class HtmlContentWidget extends StatefulWidget {
  final String content;
  final ContentType contentType;
  final double? width;
  final double? height;
  final String mermaidTheme;

  const HtmlContentWidget({
    Key? key,
    required this.content,
    required this.contentType,
    this.width = 800,
    this.height = 500,
    this.mermaidTheme = 'default',
  }) : super(key: key);

  @override
  _HtmlContentWidgetState createState() => _HtmlContentWidgetState();
}

class _HtmlContentWidgetState extends State<HtmlContentWidget> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      web.window.onMessage.listen((event) {
        if (event.data is String) {
          String message = event.data as String;
          if (message.startsWith('error:'))
            setState(() {
              _errorMessage = message;
            });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Text('HtmlElementView 只在 Web 平台可用');
    }

    if (_errorMessage != null) {
      return Text('Error: $_errorMessage');
    }

    final String viewId =
        'html-content-${DateTime.now().millisecondsSinceEpoch}';
    final String htmlContent = _generateHtmlContent();

    // Register view factory
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      return web.HTMLIFrameElement()
        ..srcdoc = js.jsify(htmlContent)
        ..style.border = 'none'
        ..allowFullscreen = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('title', 'Content Viewer'); // For accessibility
    });

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          width: widget.width ?? constraints.maxWidth,
          height: widget.height ?? constraints.maxHeight,
          constraints: BoxConstraints(maxWidth: 800, maxHeight: 800),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: HtmlElementView(viewType: viewId),
        );
      },
    );
  }

  String _generateHtmlContent() {
    if (widget.contentType == ContentType.html) {
      return _sanitizeHtml(widget.content);
    } else if (widget.contentType == ContentType.mermaid) {
      return '''
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
           <script src="https://cdn.bootcdn.net/ajax/libs/mermaid/10.9.1/mermaid.min.js"></script>
            <script>
              document.addEventListener("DOMContentLoaded", function() {
                if (typeof mermaid !== 'undefined') {
                  try {
                    mermaid.initialize({startOnLoad: false, theme: '${widget.mermaidTheme}'});
                    mermaid.run();
                  } catch (error) {
                    console.error("Mermaid error:", error);
                    window.parent.postMessage('error:' + error.message, '*');
                  }
                } else {
                  console.error("Mermaid library not loaded");
                  window.parent.postMessage('error:Mermaid library not loaded', '*');
                }
              });
            </script>
          </head>
          <body>
            <div class="mermaid">
              ${_sanitizeHtml(widget.content)}
            </div>
          </body>
        </html>
      ''';
    }
    return '';
  }

  String _sanitizeHtml(String html) {
    return html; // 此处需更强的HTML清理措施
  }
}
