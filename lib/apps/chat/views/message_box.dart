import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:gallery/apps/chat/models/data.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_downloader_web/image_downloader_web.dart';

import '../models/message.dart';
import '../models/pages.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import '../utils/markdown_extentions.dart';
import '../utils/utils.dart';
import '../utils/assistants_api.dart';

class MessageBox extends StatefulWidget {
  final Message msg;
  final bool isLast;
  final int pageId;

  MessageBox(
      {Key? key, required this.msg, this.isLast = false, required this.pageId})
      : super(key: ValueKey(msg.id));

  @override
  State createState() => MessageBoxState();
}

class MessageBoxState extends State<MessageBox> {
  static bool _hasCopyIcon = false;
  final ScrollController _attachmentscroll = ScrollController();
  final ScrollController _visionFilescroll = ScrollController();
  final assistant = AssistantsAPI();

  @override
  Widget build(BuildContext context) {
    if (widget.isLast) {
      Pages pages = Provider.of<Pages>(context, listen: true);
      return ValueListenableBuilder<Message?>(
        valueListenable: pages.getPage(widget.pageId).lastMessageNotifier,
        builder: (context, lastMsg, child) {
          return _msgBox(context, lastMsg ?? widget.msg);
        },
      );
    } else {
      return _msgBox(context, widget.msg);
    }
  }

  Widget _msgBox(BuildContext context, Message msg) {
    return msg.role != MessageTRole.system
        ? Container(
            padding: isDisplayDesktop(context)
                ? EdgeInsets.only(left: 80, right: 120)
                : null,
            margin: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                roleIcon(context, msg),
                message(context, msg),
              ],
            ),
          )
        : Container();
  }

  Widget roleIcon(BuildContext context, Message msg) {
    User user = Provider.of<User>(context);
    if (msg.role == MessageTRole.assistant)
      return image_show(user.avatar_bot ?? defaultUserBotAvatar, 16);
    else
      return image_show(user.avatar!, 16);
    // var icon = widget.msg.role == MessageTRole.user
    //     ? Icons.person
    //     : Icons.perm_identity;
    // var color =
    //     widget.msg.role == MessageTRole.user ? Colors.blue : Colors.green;

    // return Icon(
    //   icon,
    //   size: 32,
    //   color: color,
    // );
  }

  Widget message(BuildContext context, Message msg) {
    double bottom_v = 0;
    if (msg.role == MessageTRole.user) bottom_v = 20.0;
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(left: 8, bottom: bottom_v),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: msg.role == MessageTRole.user
                ? AppColors.userMsgBox
                : AppColors.aiMsgBox,
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // messageRoleName(context),
          if (msg.visionFiles.isNotEmpty)
            Container(
                height: 250, child: visionFilesList(context, msg.visionFiles)),
          if (msg.attachments.isNotEmpty)
            Container(
                height: 80, child: attachmentList(context, msg.attachments)),
          messageContent(context, msg)
        ]),
      ),
    );
  }

  Widget messageRoleName(BuildContext context, Message msg) {
    var name = msg.role == MessageTRole.user ? "You" : "Assistant";

    return Container(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(
            text: TextSpan(
          text: name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )));
  }

  Widget messageContent(BuildContext context, Message msg) {
    if (msg.role == MessageTRole.user) {
      return SelectableText(
        msg.content,
        //overflow: TextOverflow.ellipsis,
        //showCursor: false,
        maxLines: null,
        style: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
      );
    } else {
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
                  contentMarkdown(context, msg),
                  visibilityCopyButton(context, msg)
                ]),
          ));
    }
  }

  Widget visibilityCopyButton(BuildContext context, Message msg) {
    return Visibility(
        visible: _hasCopyIcon,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: IconButton(
          tooltip: "Copy",
          onPressed: () {
            Clipboard.setData(ClipboardData(text: msg.content))
                .then((value) => showMessage(context, "Copied"));
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

  Widget contentMarkdown(BuildContext context, Message msg) {
    return SelectionArea(
        child: MarkdownBody(
      data: msg.content, //markdownTest,
      //extensionSet: MarkdownExtensionSet.githubFlavored.value,
      onTapLink: (text, href, title) => launchUrl(Uri.parse(href!)),
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
        codeblockPadding: const EdgeInsets.all(10),
        codeblockDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          // color: Colors.grey,
        ),
      ),
      builders: {
        'code': CodeBlockBuilder(context),
        // 'latex': LatexElementBuilder(
        //     textStyle: const TextStyle(
        //       fontWeight: FontWeight.w100,
        //     ),
        //     textScaleFactor: 1.2),
      },
    ));
  }

  Future<void> handleDownload(
      String attachedFileName, Attachment attachFile) async {
    setState(() {
      attachFile.downloading = true;
    });
    var res =
        await assistant.downloadFile(attachFile.file_id!, attachedFileName);
    setState(() {
      attachFile.downloading = false;
    });

    showMessage(context, res);
  }

  Widget attachedFileIcon(
      BuildContext context, String attachedFileName, Attachment attachFile) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
          color: AppColors.inputBoxBackground,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: ListTile(
        dense: true,
        title: Text(attachedFileName, overflow: TextOverflow.ellipsis),
        leading: Icon(Icons.description_outlined, color: Colors.pink[300]),
        onTap: () {
          handleDownload(attachedFileName, attachFile);
        },
        trailing: (attachFile.downloading!
            ? CircularProgressIndicator()
            : Icon(Icons.download_for_offline_outlined)),
      ),
    );
  }

  Widget attachmentList(BuildContext context, attachments) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 3);
    final double childAspectRatio = (width / crossAxisCount) / 80.0;
    final hpaddng = isDisplayDesktop(context) ? 15.0 : 15.0;
    return GridView.builder(
      key: UniqueKey(),
      controller: _attachmentscroll,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: hpaddng, vertical: 5),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 20.0,
        childAspectRatio: childAspectRatio,
        crossAxisCount: crossAxisCount,
      ),
      itemCount: attachments.entries.length,
      itemBuilder: (BuildContext context, int index) {
        MapEntry entry = attachments.entries.elementAt(index);
        return attachedFileIcon(context, entry.key, entry.value);
      },
    );
  }

  Widget visionFilesList(BuildContext context, visionFiles) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 3);
    final double childAspectRatio = (width / crossAxisCount) / 400.0;
    final hpaddng = isDisplayDesktop(context) ? 15.0 : 15.0;
    return GridView.builder(
      key: UniqueKey(),
      controller: _visionFilescroll,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: hpaddng, vertical: 5),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 20.0,
        childAspectRatio: childAspectRatio,
        crossAxisCount: crossAxisCount,
      ),
      itemCount: visionFiles.entries.length,
      itemBuilder: (BuildContext context, int index) {
        MapEntry entry = visionFiles.entries.elementAt(index);
        return contentImage(context, entry.key, entry.value);
      },
    );
  }

  Widget loadImage(BuildContext context, _filename, _content, {height, width}) {
    if (_content.url.isNotEmpty) {
      return Image.network(
        _content.url,
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
    } else if (_content.bytes.isNotEmpty) {
      return Image.memory(
        _content.bytes,
        height: height,
        width: width,
        errorBuilder: (context, error, stackTrace) => Text('load image failed'),
      );
    } else
      return Text("load image failed");
  }

  Widget contentImage(BuildContext context, _filename, _content) {
    return GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(child: loadImage(context, _filename, _content));
              });
        },
        onLongPressStart: (details) {
          _showDownloadMenu(
              context, _filename, _content, details.globalPosition);
        },
        child:
            loadImage(context, _filename, _content, height: 250, width: 200));
  }

  void _showDownloadMenu(
      BuildContext context, _filename, _content, Offset position) {
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
    ).then((selectedValue) async {
      if (selectedValue == 'download') {
        if (_content.url.isNotEmpty) {
          // var uri = Uri.parse(widget.val["fileUrl"]);
          // String filenameExp = uri.pathSegments.last;
          // String filename = filenameExp.split('=').first;
          await WebImageDownloader.downloadImageFromWeb(
            name: "ai",
            _content.url,
          );
        } else if (_content.bytes.isNotEmpty)
          await WebImageDownloader.downloadImageFromUInt8List(
            uInt8List: _content.bytes,
          );
      }
    });
  }
}
