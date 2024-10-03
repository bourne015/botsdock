import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:gallery/apps/chat/models/data.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_downloader_web/image_downloader_web.dart';

import '../models/anthropic/schema/schema.dart' as anthropic;
import '../models/message.dart';
import '../models/pages.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import '../utils/markdown_extentions.dart';
import '../utils/utils.dart';
import '../utils/assistants_api.dart';
import './htmlcontent.dart';

class MessageBox extends StatefulWidget {
  final Message msg;
  final bool isLast;
  final int pageId;
  final Stream<Message> messageStream;

  MessageBox({
    Key? key,
    required this.msg,
    this.isLast = false,
    required this.pageId,
    required this.messageStream,
  }) : super(key: ValueKey(msg.id));

  @override
  State createState() => MessageBoxState();
}

class MessageBoxState extends State<MessageBox> {
  late final ScrollController _attachmentscroll;
  late final ScrollController _visionFilescroll;
  late final assistant;
  late final Stream<Message> _messageStream;

  @override
  void initState() {
    super.initState();
    _attachmentscroll = ScrollController();
    _visionFilescroll = ScrollController();
    assistant = AssistantsAPI();
    _messageStream =
        widget.messageStream.where((msg) => msg.id == widget.msg.id);
  }

  @override
  void dispose() {
    _attachmentscroll.dispose();
    _visionFilescroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //do not show tool result message
    if (widget.msg.role == MessageTRole.user &&
        (widget.msg.content is List &&
            widget.msg.content[0] is anthropic.ToolResultBlock))
      return Container();

    return widget.msg.role == MessageTRole.user ||
            widget.msg.role == MessageTRole.assistant
        ? Container(
            margin: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                roleIcon(context, widget.msg),
                _msgBox(context)
              ],
            ),
          )
        : Container();
  }

  Widget _msgBox(BuildContext context) {
    return StreamBuilder<Message>(
      stream: _messageStream,
      initialData: widget.msg,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.onThinking && widget.isLast) {
          return const ThinkingIndicator();
        }
        if (snapshot.hasData) {
          return message(context, snapshot.data!);
        }
        return const ThinkingIndicator();
      },
    );
  }

  Widget roleIcon(BuildContext context, Message msg) {
    User user = Provider.of<User>(context, listen: false);
    if (msg.role == MessageTRole.assistant)
      return image_show(user.avatar_bot ?? defaultUserBotAvatar, 16);
    else if (msg.role == MessageTRole.user)
      return image_show(user.avatar!, 16);
    else
      return SizedBox.shrink();
  }

  Widget message(BuildContext context, Message msg) {
    double bottom_v = 0;
    if (msg.role == MessageTRole.user) bottom_v = 20.0;
    return Flexible(
      // key: UniqueKey(),
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
            //Claude images url saved in visionFilesList
            Container(
                height: 250, child: visionFilesList(context, msg.visionFiles)),
          if (msg.attachments.isNotEmpty)
            Container(
                height: 80, child: attachmentList(context, msg.attachments)),
          if (msg.content is List)
            ...msg.content.map((_content) {
              if (_content.type == "text")
                return messageContent(context, msg.role, _content.text);
              // else if (_content.type == "image")
              //   return contentImage(context, imageBytes: _content.source.data);
              else if (_content.type == "image_url")
                return contentImage(context, imageUrl: _content.imageUrl.url);
              else if (_content.type == "tool_use" &&
                  _content.name == "save_artifact") {
                return buildArtifact(context, _content.input);
              } else if (_content.type == "tool_result") {
                return messageContent(context, msg.role, "tool test");
              } else
                return SizedBox.shrink();
            }).toList()
          else if (msg.content is String)
            messageContent(context, msg.role, msg.content),
          if (msg.toolCalls.isNotEmpty)
            ...msg.toolCalls.map((tool) {
              if (!isValidJson(tool.function.arguments))
                return messageContent(
                  context,
                  msg.role,
                  tool.function.arguments,
                );
              if (tool.function.name == "save_artifact")
                return buildArtifact(
                    context, json.decode(tool.function.arguments));
              return SizedBox.shrink();
            }).toList(),
        ]),
      ),
    );
  }

  bool isValidJson(String jsonString) {
    try {
      json.decode(jsonString);
      return true;
    } on FormatException catch (_) {
      return false;
    }
  }

  /**
   * build Artifact: only support Html
   */
  Widget buildArtifact(BuildContext context, dynamic func) {
    if (func["type"] == null) return SizedBox.shrink();
    if (func["type"] != "html" && func["type"] != "mermaid")
      return SelectableText(
        func["type"] + func["content"],
        style: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
      );
    return Container(
      padding: EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Text("Artifact: " + func["artifactName"],
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          HtmlContentWidget(
            content: func["content"] ?? "",
            contentType: func["type"] == "mermaid"
                ? ContentType.mermaid
                : ContentType.html,
          )
        ],
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

  Widget messageContent(
      BuildContext context, String role, String? _textContent) {
    if (role == MessageTRole.user) {
      return SelectableText(
        _textContent ?? "",
        //overflow: TextOverflow.ellipsis,
        //showCursor: false,
        maxLines: null,
        style: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          contentMarkdown(context, _textContent ?? ""),
          if (_textContent != null && _textContent.isNotEmpty)
            IconButton(
              tooltip: "Copy",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _textContent))
                    .then((value) => showMessage(context, "Copied"));
              },
              icon: const Icon(Icons.copy, size: 15),
            )
        ],
      );
    }
  }

  Widget contentMarkdown(BuildContext context, String msg) {
    try {
      return SelectionArea(
          // key: UniqueKey(),
          child: MarkdownBody(
        // key: UniqueKey(),
        data: msg, //markdownTest,
        // selectable: true,
        shrinkWrap: true,
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
            borderRadius: BORDERRADIUS10,
            // color: Colors.grey,
          ),
        ),
        builders: {
          'code': CodeBlockBuilder(context),
          'latex': LatexElementBuilder(
              textStyle: const TextStyle(
                fontWeight: FontWeight.w100,
              ),
              textScaleFactor: 1.2),
        },
      ));
    } catch (e, stackTrace) {
      print("markdown error: $e");
      print("markdown error1: $stackTrace");
      return Text("error mark");
    }
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
        return contentImage(
          context,
          filename: entry.key,
          imageUrl: entry.value.url,
          imageBytes: entry.value.bytes,
        );
      },
    );
  }

  Widget loadImage(BuildContext context,
      {filename, imageurl, imagebytes, height, width}) {
    if (imageurl != null && imageurl.isNotEmpty) {
      return Image.network(
        imageurl,
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
        errorBuilder: (context, error, stackTrace) =>
            Text('load image url failed'),
      );
    } else if (imagebytes != null && imagebytes.isNotEmpty) {
      return Image.memory(
        imagebytes,
        height: height,
        width: width,
        errorBuilder: (context, error, stackTrace) =>
            Text('load image bytes failed'),
      );
    } else
      return Text("load image failed");
  }

  Widget contentImage(BuildContext context, {filename, imageUrl, imageBytes}) {
    return GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    child: loadImage(
                  context,
                  filename: filename,
                  imageurl: imageUrl,
                  imagebytes: imageBytes,
                ));
              });
        },
        onLongPressStart: (details) {
          _showDownloadMenu(context, details.globalPosition,
              filename: filename, imageUrl: imageBytes, imageBytes: imageBytes);
        },
        child: loadImage(context,
            filename: filename,
            imageurl: imageUrl,
            imagebytes: imageBytes,
            height: 250,
            width: 200));
  }

  void _showDownloadMenu(BuildContext context, Offset position,
      {filename, imageUrl, imageBytes}) {
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
        if (imageUrl != null && imageUrl.isNotEmpty) {
          // var uri = Uri.parse(widget.val["fileUrl"]);
          // String filenameExp = uri.pathSegments.last;
          // String filename = filenameExp.split('=').first;
          await WebImageDownloader.downloadImageFromWeb(
            name: "ai",
            imageUrl,
          );
        } else if (imageBytes != null && imageBytes.isNotEmpty)
          await WebImageDownloader.downloadImageFromUInt8List(
            uInt8List: imageBytes,
          );
      }
    });
  }
}
