import 'dart:convert';

import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';
import 'package:botsdock/apps/chat/vendor/messages/deepseek.dart';
import 'package:botsdock/apps/chat/vendor/messages/gemini.dart';
import 'package:botsdock/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:botsdock/apps/chat/models/data.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import '../utils/markdown_extentions.dart';
import '../utils/utils.dart';
import '../vendor/assistants_api.dart';
import './htmlcontent.dart';

class MessageBox extends StatefulWidget {
  final Message msg;
  final bool isLast;
  final bool isSameRole;
  final int pageId;
  final String? model;
  final Stream<Message> messageStream;

  MessageBox({
    Key? key,
    required this.msg,
    this.isLast = false,
    this.isSameRole = false,
    required this.pageId,
    this.model,
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
  bool isExpanded = true;
  bool isGoogleList = false;

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
    isGoogleList = isGoogleResults();
    //do not show tool result message
    if (!isGoogleList &&
        widget.msg.role == MessageTRole.user &&
        (widget.msg.content is List &&
            widget.msg.content[0] is anthropic.ToolResultBlock))
      return Container();

    return widget.msg.role == MessageTRole.user ||
            widget.msg.role == MessageTRole.assistant ||
            (widget.msg.role == MessageTRole.tool && isGoogleList) ||
            widget.msg.role == "model"
        ? Container(
            margin: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                widget.isSameRole || isGoogleList
                    ? SizedBox(width: 32, height: 32)
                    : roleIcon(context, widget.msg),
                isGoogleList ? googleResultList(context) : _msgBox(context)
              ],
            ),
          )
        : SizedBox.shrink();
  }

  Widget googleResultList(BuildContext context) {
    List results;

    if (GPTModel.all.contains(widget.model!)) {
      if (!isValidJson(widget.msg.content[0].text)) {
        return SizedBox.shrink();
      }
      results = jsonDecode(widget.msg.content[0].text)["google_result"];
    } else {
      if (!isValidJson(widget.msg.content[0].content.value))
        return SizedBox.shrink();
      results =
          jsonDecode(widget.msg.content[0].content.value)["google_result"];
    }
    return PopupMenuButton<String>(
      icon: Container(
          decoration: BoxDecoration(
            borderRadius: BORDERRADIUS15,
            color: AppColors.userMsgBox,
            border: Border.all(width: 2, color: Colors.grey),
          ),
          child: Row(children: [
            Image.asset("assets/images/google.png", height: 18, width: 18),
            Text("Google搜索结果",
                style: TextStyle(fontSize: 10.5, color: AppColors.subTitle)),
          ])),
      // iconColor: Colors.blueGrey[500],
      color: AppColors.appBarBackground,
      position: PopupMenuPosition.over,
      // padding: EdgeInsets.all(10),
      itemBuilder: (BuildContext context) {
        return results.map((x) {
          return PopupMenuItem<String>(
            // value: x["title"],
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              leading: Icon(Icons.link_outlined),
              onTap: () {
                launchUrl(Uri.parse(x["link"]));
                Navigator.of(context).pop();
              },
              title: Text(
                x["title"] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                x["snippet"] ?? "",
                style: TextStyle(fontSize: 10.5, color: AppColors.subTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  bool isGoogleResults() {
    try {
      if (GPTModel.all.contains(widget.model!) && widget.msg.role == "tool") {
        if (widget.msg.content.length <= 0) return false;
        if (widget.msg.content[0].text != null &&
            widget.msg.content[0].text.startsWith("{\"google_result")) {
          return true;
        }
      } else if (ClaudeModel.all.contains(widget.model) &&
          widget.msg.content[0] is anthropic.ToolResultBlock) {
        if (widget.msg.content[0].content != null &&
            widget.msg.content[0].content.value
                .startsWith("{\"google_result")) {
          return true;
        }
      }
    } catch (e) {
      debugPrint("check google result error: $e");
    }
    return false;
  }

  Widget _msgBox(BuildContext context) {
    return StreamBuilder<Message>(
      stream: _messageStream,
      initialData: widget.msg,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.onProcessing && widget.isLast) {
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
    String _contentAll = '';
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
          if (widget.isLast &&
              msg is DeepSeekMessage &&
              msg.reasoning_content.isNotEmpty)
            ThinkingContent(context, msg.role, msg.onThinking, msg),
          if (msg.content is List)
            ...msg.content.map((_content) {
              if (GeminiModel.all.contains(widget.model!)) {
                if (_content is GeminiTextContent) {
                  _contentAll += _content.text ?? "";
                  return messageContent(context, msg.role, _content.text);
                } else if (_content is GeminiPart3) {
                  return buildArtifact(context, _content.args);
                } else if (_content is GeminiPart1) {
                  //inlineData
                  // return contentImage(context,
                  //     imageUrl: _content.inlineData?.data);
                  return SizedBox.shrink();
                } else if (_content is GeminiPart2) {
                  return SizedBox.shrink();
                }
              } else {
                if (_content.type == "text") {
                  _contentAll += _content.text ?? "";
                  return messageContent(context, msg.role, _content.text);
                }
                // else if (_content.type == "image")
                //   return contentImage(context, imageBytes: _content.source.data);
                else if (_content.type == "image_url")
                  // return contentImage(context, imageUrl: _content.imageUrl.url);
                  return SizedBox.shrink();
                else if (_content.type == "tool_use") {
                  if (_content.name == "save_artifact")
                    return buildArtifact(context, _content.input);
                  else if (_content.name == "webpage_fetch") {
                    _contentAll += _content.input["url"] ?? "";
                    return messageContent(
                        context, msg.role, _content.input["url"]);
                  } else
                    return SizedBox.shrink();
                } else if (_content.type == "tool_result") {
                  return messageContent(context, msg.role, "tool test");
                } else
                  return SizedBox.shrink();
              }
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
              else if (tool.function.name == "google_search") {
                return SizedBox.shrink(); //TODO
              } else if (tool.function.name == "webpage_fetch") {
                var arg = jsonDecode(tool.function.arguments);
                _contentAll += arg["url"] ?? "";
                return messageContent(context, msg.role, arg["url"]);
              }
              return SizedBox.shrink();
            }).toList(),
          if (_contentAll.isNotEmpty && msg.role != MessageTRole.user)
            IconButton(
              tooltip: "Copy",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _contentAll))
                    .then((value) => showMessage(context, "Copied"));
              },
              icon: const Icon(Icons.copy, size: 15),
            )
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
    if (!supportedContentType.contains(func["type"].toLowerCase())) {
      // return SelectableText(
      //   func["type"] + func["content"],
      //   style: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
      // );
      return contentMarkdown(context, func["content"]);
    }
    return Container(
      padding: EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Text(func["artifactName"],
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          HtmlContentWidget(
            content: func["content"] ?? "",
            contentType: func["type"].toLowerCase(),
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

/**
 * Chain of Thought content
 * only DeepSeek
 */
  Widget ThinkingContent(
      BuildContext context, String role, bool onThinking, DeepSeekMessage msg) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.thinkingMsgBox,
            borderRadius: BORDERRADIUS15,
          ),
          constraints: const BoxConstraints(minWidth: double.infinity),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thinkingTitle(onThinking),
                thinkingMsg(msg),
              ]),
        ),
        thinkingExpand(),
        thinkingClose(msg),
      ],
    );
  }

  Widget thinkingMsg(DeepSeekMessage msg) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.bottomLeft,
      curve: Curves.easeInOut,
      child: isExpanded
          ? msg.reasoning_content.isNotEmpty
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: contentMarkdown(
                      context,
                      msg.reasoning_content,
                      pSize: 13.0,
                    ),
                  ),
                )
              : const SizedBox.shrink()
          : const SizedBox.shrink(),
    );
  }

  Widget thinkingTitle(bool onThinking) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        onThinking
            ? SpinKitRipple(
                color: Colors.red,
                size: AppSize.generatingAnimation,
              )
            : Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
              ),
        Text(
          onThinking ? "思考中" : "思维链",
          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  Widget thinkingClose(DeepSeekMessage msg) {
    return Positioned(
      top: 12,
      right: 5,
      child: IconButton(
        icon: const Icon(Icons.close),
        // iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: "delete",
        visualDensity: VisualDensity.compact,
        onPressed: () {
          setState(() {
            msg.reasoning_content = '';
          });
        },
      ),
    );
  }

  Widget thinkingExpand() {
    return Positioned(
        top: 12,
        left: 8,
        child: Tooltip(
          message: isExpanded ? "收起内容" : "展开内容",
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: isExpanded ? 0 : 0.5,
              child: const Icon(
                Icons.expand_less,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ));
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
          // if (_textContent != null && _textContent.isNotEmpty)
          //   IconButton(
          //     tooltip: "Copy",
          //     onPressed: () {
          //       Clipboard.setData(ClipboardData(text: _textContent))
          //           .then((value) => showMessage(context, "Copied"));
          //     },
          //     icon: const Icon(Icons.copy, size: 15),
          //   )
        ],
      );
    }
  }

  Widget contentMarkdown(BuildContext context, String msg, {double? pSize}) {
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
          p: TextStyle(fontSize: pSize ?? 16.0, color: AppColors.msgText),
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
    var res = 'can not download';
    if (GPTModel.all.contains(widget.model!))
      res = await assistant.downloadFile(attachFile.file_id!, attachedFileName);
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        clipBehavior: Clip.hardEdge,
        child: FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          image: NetworkImage(imageurl),
          fit: BoxFit.fitWidth,
          height: height,
          width: width,
          fadeInDuration: const Duration(milliseconds: 10),
          imageErrorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image_outlined),
        ),
      );
    } else if (imagebytes != null && imagebytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          height: height,
          width: width,
          image: MemoryImage(imagebytes),
          fadeOutDuration: const Duration(milliseconds: 10),
          imageErrorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image),
        ),
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
              filename: filename, imageUrl: imageUrl, imageBytes: imageBytes);
        },
        child: loadImage(context,
            filename: filename,
            imageurl: imageUrl,
            imagebytes: imageBytes,
            height: 250.0,
            width: 200.0));
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
          downloadImage(fileUrl: imageUrl);
        } else if (imageBytes != null && imageBytes.isNotEmpty) {
          downloadImage(imageData: imageBytes);
        }
      }
    });
  }
}
