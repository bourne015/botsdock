import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final double width;
  final double height;

  HtmlContentWidget({
    required this.htmlContent,
    this.width = 800, //double.infinity,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    // 创建唯一的 id
    final String viewId =
        'html-content-${DateTime.now().millisecondsSinceEpoch}';

    // 注册视图工厂
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..srcdoc = htmlContent
        ..style.border = 'none'
        ..allowFullscreen = true
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.only(top: 5),
      constraints: BoxConstraints(maxHeight: 800, maxWidth: 800),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10))),
      clipBehavior: Clip.hardEdge,
      child: kIsWeb
          ? HtmlElementView(viewType: viewId)
          : Text('HtmlElementView 只在 Web 平台可用'),
    );
  }
}
