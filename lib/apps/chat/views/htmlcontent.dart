import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final double width;
  final double height;

  HtmlContentWidget({
    required this.htmlContent,
    this.width = 800,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.only(top: 5),
      constraints: BoxConstraints(maxHeight: 1200, maxWidth: 1200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: htmlContent),
        onWebViewCreated: (InAppWebViewController controller) {
          // 如果需要在 WebView 创建后执行一些操作，可以在这里添加代码
        },
        onLoadStop: (InAppWebViewController controller, Uri? url) {
          // 页面加载完成后的回调，如果需要在加载完成后执行一些操作，可以在这里添加代码
        },
      ),
    );
  }
}
