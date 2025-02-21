import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/data/adaptive.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;
import 'dart:js_interop';
import 'dart:async';

/// 内容类型枚举
enum ContentType { html, mermaid }

/// HTML内容显示组件
class HtmlContentWidget extends StatefulWidget {
  final String content;
  final ContentType contentType;
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
    this.width = 800,
    this.height = 500,
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
  String? _errorMessage;
  Timer? _loadingTimer;
  final _loadCompleter = Completer<void>();
  StreamSubscription? _messageSubscription;
  static final Set<String> _registeredViewIds = {};
  late final String viewId;

  @override
  void initState() {
    super.initState();
    viewId = 'html-content-${DateTime.now().millisecondsSinceEpoch}';
    _setupLoading();
    _setupViewFactory();
  }

  void _setupLoading() {
    _loadingTimer = Timer(widget.loadingTimeout, () {
      if (_isLoading) {
        _handleLoadError('加载超时');
      }
    });

    if (kIsWeb) {
      _messageSubscription = web.window.onMessage.listen(_handleMessage);
    }
  }

  void _setupViewFactory() {
    if (!_registeredViewIds.contains(viewId)) {
      ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        return web.HTMLIFrameElement()
          ..srcdoc = _generateHtmlContent() as JSAny
          ..style.border = 'none'
          ..allowFullscreen = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = isDisplayDesktop(context) ? 'auto' : 'none'
          ..setAttribute('title', 'Content Viewer');
      });
      _registeredViewIds.add(viewId);
    }
  }

  void _handleMessage(web.MessageEvent event) {
    if (event.data is String) {
      String message = event.data as String;
      if (message == 'loaded') {
        _handleLoadComplete();
      } else if (message.startsWith('error:')) {
        _handleLoadError(message.substring(6));
      }
    }
  }

  void _handleLoadComplete() {
    if (!_loadCompleter.isCompleted && mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadingTimer?.cancel();
      widget.onLoadComplete?.call();
      _loadCompleter.complete();
    }
  }

  void _handleLoadError(String error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
      _loadingTimer?.cancel();
      widget.onLoadError?.call(error);
    }
  }

  String _generateHtmlContent() {
    final baseHtml = '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { margin: 0; padding: 0; }
            .content-wrapper { 
              opacity: 0; 
              transition: opacity 0.3s ease-in-out; 
            }
            .content-wrapper.loaded { 
              opacity: 1; 
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

    if (widget.contentType == ContentType.mermaid) {
      return '''
        $baseHtml
        <script src="/assets/assets/mermaid.min.js"></script>
        <script>
          document.addEventListener("DOMContentLoaded", function() {
            try {
              mermaid.initialize({
                startOnLoad: true,
                theme: '${widget.mermaidTheme}',
                securityLevel: 'strict'
              });
            } catch (error) {
              notifyParent('error:' + error.message);
            }
          });
        </script>
        </head>
        <body>
          <div class="content-wrapper">
            <div class="mermaid">
              ${_sanitizeHtml(widget.content)}
            </div>
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
            ${_sanitizeHtml(widget.content)}
          </div>
        </body>
      </html>
      ''';
    }
  }

  String _sanitizeHtml(String html) {
    // return html
    //     .replaceAll('<script>', '&lt;script&gt;')
    //     .replaceAll('</script>', '&lt;/script&gt;');
    return html;
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Text('HtmlElementView 只在 Web 平台可用');
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final effectiveWidth = widget.width?.clamp(0.0, constraints.maxWidth) ??
            constraints.maxWidth.clamp(0.0, 800.0);
        final effectiveHeight =
            widget.height?.clamp(0.0, constraints.maxHeight) ??
                constraints.maxHeight.clamp(0.0, 800.0);

        return Stack(
          children: [
            Container(
              width: effectiveWidth,
              height: effectiveHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildContentView(),
            ),
            // if (_isLoading) _buildLoadingWidget(),
          ],
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        // color: Colors.white.withValues(alpha: 0.7),
        child: widget.loadingWidget ??
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(strokeWidth: 2.0),
                SizedBox(height: 10),
                Text('loading...'),
              ],
            ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            '加载失败：$_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return HtmlElementView(viewType: viewId);
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _messageSubscription?.cancel();
    if (!_loadCompleter.isCompleted) {
      _loadCompleter.complete();
    }
    super.dispose();
  }
}
