// import 'dart:html' as html;
// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../utils/markdown_extentions.dart';
import '../utils/syntax_hightlighter.dart';
import '../utils/utils.dart';

class MessageBox extends StatefulWidget {
  final Map val;

  MessageBox({super.key, required this.val});

  @override
  State createState() => MessageBoxState();
}

class MessageBoxState extends State<MessageBox> {
  static bool _hasCopyIcon = false;
  @override
  Widget build(BuildContext context) {
    return widget.val['role'] != MessageRole.system
        ? Container(
            padding: isDisplayDesktop(context)
                ? EdgeInsets.only(left: 80, right: 120)
                : null,
            margin: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                roleIcon(context),
                message(context),
              ],
            ),
          )
        : Container();
  }

  Widget roleIcon(BuildContext context) {
    var icon = widget.val['role'] == MessageRole.user
        ? Icons.person
        : Icons.perm_identity;
    var color =
        widget.val['role'] == MessageRole.user ? Colors.blue : Colors.green;

    return Icon(
      icon,
      size: 32,
      color: color,
    );
  }

  Widget message(BuildContext context) {
    double bottom_v = 0;
    if (widget.val['role'] == MessageRole.user) bottom_v = 30.0;
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(bottom: bottom_v),
        padding:
            EdgeInsets.only(top: 1.0, bottom: 1.0, right: 10.0, left: 10.0),
        decoration: BoxDecoration(
            color: widget.val['role'] == MessageRole.user
                ? AppColors.userMsgBox
                : AppColors.aiMsgBox,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            )),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          messageRoleName(context),
          //if (widget.val["type"] != MsgType.text)
          if (widget.val['role'] == MessageRole.user)
            contentAttachment(context, widget.val["fileBytes"]),
          messageContent(context)
        ]),
      ),
    );
  }

  Widget messageRoleName(BuildContext context) {
    var name = widget.val['role'] == MessageRole.user ? "You" : "Assistant";

    return Container(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(
            text: TextSpan(
          text: name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )));
  }

  Widget messageContent(BuildContext context) {
    if (widget.val["type"] == MsgType.image &&
        widget.val['role'] == MessageRole.assistant) {
      // String imgBase64Str = widget.val['fileBytes'];
      // final Uint8List imgUint8List = base64Decode(imgBase64Str);
      //String imageB64Url = "data:image/png;base64,$imgBase64Str";
      //final Uint8List imgUint8List = widget.val['fileBytes'];
      return contentImage(context);
    } else if (widget.val['role'] == MessageRole.user) {
      return SelectableText(
        widget.val['content'],
        //overflow: TextOverflow.ellipsis,
        //showCursor: false,
        maxLines: null,
        style: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
      );
    } else {
      return wrapContentbyCopy(context);
    }
  }

  Widget visibilityCopyButton(BuildContext context) {
    return Visibility(
        visible: _hasCopyIcon,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: IconButton(
          tooltip: "Copy",
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.val['content']))
                .then((value) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(milliseconds: 200),
                        content: Text('Copied'),
                      ),
                    ));
          },
          icon: const Icon(
            Icons.copy,
            size: 15,
          ),
        ));
  }

  void _setHovering(bool hovering) {
    setState(() {
      _hasCopyIcon = hovering;
    });
  }

  Widget wrapContentbyCopy(BuildContext context) {
    return MouseRegion(
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: Container(
            padding: const EdgeInsets.all(0),
            margin: const EdgeInsets.all(0),
            //color: Colors.grey[200],
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  contentMarkdown(context),
                  visibilityCopyButton(context)
                ])));
  }

  Widget contentMarkdown(BuildContext context) {
    return MarkdownBody(
      data: widget.val['content'], //markdownTest,
      selectable: true,
      syntaxHighlighter: Highlighter(),
      //extensionSet: MarkdownExtensionSet.githubFlavored.value,
      onTapLink: (text, href, title) => launchUrl(Uri.parse(href!)),
      onSelectionChanged: (text, selection, cause) {},
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          ...[LatexBlockSyntax()],
        ],
        <md.InlineSyntax>[
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ...[LatexInlineSyntax()],
        ],
      ),
      styleSheetTheme: MarkdownStyleSheetBaseTheme.platform,
      styleSheet: MarkdownStyleSheet(
        //h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        //h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        p: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
        code: const TextStyle(
          inherit: false,
          color: AppColors.msgText,
          fontWeight: FontWeight.bold,
        ),
      ),
      builders: {
        'code': CodeBlockBuilder(context, Highlighter()),
        'latex': LatexElementBuilder(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w100,
            ),
            textScaleFactor: 1.2),
      },
    );
  }

  Widget contentAttachment(BuildContext context, fileBytes) {
    if (widget.val["type"] == MsgType.image) {
      return contentImage(context);
    } else if (widget.val["type"] == MsgType.file) {
      return contentFile(context, fileBytes);
    }
    return Container();
  }

  Widget contentFile(BuildContext context, imageB64Url) {
    return Container(
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
          //color: AppColors.inputBoxBackground,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(1),
      child: InputChip(
        side: BorderSide.none,
        label: Text(widget.val["fileName"]!),
        avatar: const Icon(
          Icons.file_copy_outlined,
          size: 16,
        ),
        onDeleted: null,
        onPressed: () {},
      ),
    );
  }

  Widget loadImage(BuildContext context, {height, width}) {
    if (widget.val["fileUrl"] != null) {
      return Image.network(
        widget.val["fileUrl"],
        height: height,
        width: width,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Text('load image failed'),
      );
    } else if (widget.val["fileBytes"] != null) {
      return Image.memory(
        widget.val["fileBytes"],
        height: height,
        width: width,
        errorBuilder: (context, error, stackTrace) => Text('load image failed'),
      );
    } else
      return Text("load image failed");
  }

  Widget contentImage(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (widget.val["fileUrl"] != null || widget.val["fileBytes"] != null)
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(child: loadImage(context));
                });
        },
        onLongPressStart: (details) {
          // if (imgData != null)
          //   _showDownloadMenu(context, details.globalPosition, imgData);
        },
        child: loadImage(context, height: 250, width: 200));
  }

/*
  void _showDownloadMenu(BuildContext context, Offset position, imageUrl) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx, // Left
      position.dy, // Top
      overlay!.size.width - position.dx, // Right
      overlay.size.height - position.dy, // Bottom
    );

    showMenu(
      context: context,
      position: positionRect,
      items: <PopupMenuEntry>[
        const PopupMenuItem(
          value: 'download',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text("download"),
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text("share"),
          ),
        ),
      ],
    ).then((selectedValue) {
      if (selectedValue == 'download') {
        _downloadImage(imageUrl);
      }
    });
  }

  void _downloadImage(Uint8List imageData) {
    String base64Data = base64Encode(imageData);
    final String url = 'data:image/png;base64,$base64Data';
    // create HTML的Anchor Element
    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..download = "ai"; // optional: download name
    anchor.click();
  }
  */
}
