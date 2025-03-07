import 'dart:convert';

import 'package:botsdock/apps/chat/utils/logger.dart';
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
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final String role;
  final onGenerating;
  final Stream<Message> messageStream;

  MessageBox({
    Key? key,
    required this.msg,
    this.isLast = false,
    this.isSameRole = false,
    required this.pageId,
    this.model,
    required this.role,
    this.onGenerating,
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
  bool isNotEmpty = false;
  double artifactWidth = Artifact_MIN_W;
  double artifactHight = Artifact_MIN_H;
  bool expandedSearchResults = false;
  bool _hasCopyIcon = false;

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
    messageContentLists(context, widget.msg);
    if (!isNotEmpty && !widget.isLast) return SizedBox.shrink();

    return widget.role == MessageTRole.user ||
            widget.role == MessageTRole.assistant ||
            widget.role == MessageTRole.tool ||
            widget.role == MessageTRole.model
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              roleIcon(context, widget.msg),
              _msgBox(context),
            ],
          )
        : SizedBox.shrink();
  }

  Widget googleResultList(BuildContext context, List results) {
    double card_w = expandedSearchResults ? resultCard_W * 4 : resultCard_W;
    double card_h = expandedSearchResults ? resultCard_H : resultCard_H;

    if (!isDisplayDesktop(context)) {
      card_w = 250;
    }
    return Row(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          constraints: BoxConstraints(
            maxHeight: resultIcon_H,
            maxWidth: !isDisplayDesktop(context)
                ? resultIcon_W
                : expandedSearchResults
                    ? resultIcon_W
                    : resultIconExpand_W,
          ),
          // width: expandSearchResults ? resultIcon_W : resultIconExpand_W,
          // height: resultIcon_H,
          decoration: BoxDecoration(
            color: AppColors.userMsgBox,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ListTile(
            isThreeLine: isDisplayDesktop(context) && expandedSearchResults
                ? true
                : false,
            dense: true,
            leading: CircleAvatar(
              backgroundImage: AssetImage("assets/images/google.png"),
              radius: 12,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 5),
            title: isDisplayDesktop(context)
                ? Text(
                    "搜索结果",
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  )
                : null,
            titleTextStyle: TextStyle(
              fontSize: 14,
            ),
            subtitle: isDisplayDesktop(context)
                ? Text(
                    "获得${results.length}条搜索结果",
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  )
                : null,
            subtitleTextStyle: TextStyle(fontSize: 10.5, color: Colors.grey),
            trailing: IconButton(
                tooltip: expandedSearchResults ? "收起" : "展开",
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    expandedSearchResults = !expandedSearchResults;
                  });
                },
                icon: Icon(expandedSearchResults
                    ? Icons.keyboard_double_arrow_right
                    : Icons.keyboard_double_arrow_left)),
          ),
        ),
        AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: card_w,
            height: expandedSearchResults ? card_h : 1,
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.userMsgBox,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: Visibility(
                visible: expandedSearchResults,
                child: CarouselView(
                  itemSnapping: true,
                  shrinkExtent: 100,
                  scrollDirection: Axis.horizontal,
                  itemExtent: resultCard_W,
                  backgroundColor: AppColors.userMsgBox,
                  shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS15),
                  // padding: EdgeInsets.all(20),
                  onTap: (i) {
                    launchUrl(Uri.parse(results[i]["link"]));
                  },
                  children: results.map((x) {
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape:
                          RoundedRectangleBorder(borderRadius: BORDERRADIUS15),
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        child: Wrap(
                          direction: Axis.horizontal,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "${results.indexOf(x) + 1}.${x["title"]}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    label: Text(
                                      "${Uri.parse(x["link"]).host.split('.')[1]}",
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(fontSize: 10.5),
                                    ),
                                    onPressed: null,
                                    icon: Icon(Icons.cloud_done, size: 15),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )))
      ],
    );
  }

  Widget _msgBox(BuildContext context) {
    return StreamBuilder<Message>(
      stream: _messageStream,
      initialData: widget.msg,
      builder: (context, snapshot) {
        if (widget.onGenerating) {
          if (!snapshot.hasData ||
              snapshot.data!.onProcessing && widget.isLast) {
            return const ThinkingIndicator();
          }
        }
        if (snapshot.hasData) {
          return message(context, snapshot.data!);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget roleIcon(BuildContext context, Message msg) {
    User user = Provider.of<User>(context, listen: false);
    if (widget.isSameRole) return SizedBox(width: 32, height: 32);
    if (widget.role == MessageTRole.assistant)
      return Container(
        margin: EdgeInsets.only(top: 7),
        child: image_show(user.avatar_bot ?? defaultUserBotAvatar, 16),
      );
    else if (widget.role == MessageTRole.user)
      return Container(
        margin: EdgeInsets.only(top: 7),
        child: image_show(user.avatar!, 16),
      );
    else
      return SizedBox(width: 32, height: 32);
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
            color: msg.role == MessageTRole.user && !isGoogleList
                ? AppColors.userMsgBox
                : AppColors.aiMsgBox,
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: messageContentLists(context, msg),
        ),
      ),
    );
  }

  List<Widget> messageContentLists(BuildContext context, Message msg) {
    List<Widget> contentWidgets = [];

    try {
      if (msg.visionFiles.isNotEmpty) {
        //Claude images url saved in visionFilesList
        contentWidgets.add(Container(
          height: 250,
          child: visionFilesList(context, msg.visionFiles),
        ));
      }
      if (msg.attachments.isNotEmpty) {
        contentWidgets.add(Container(
          height: 80,
          child: attachmentList(context, msg.attachments),
        ));
      }
      if (widget.isLast &&
          msg is DeepSeekMessage &&
          msg.reasoning_content.isNotEmpty) {
        contentWidgets
            .add(ThinkingContent(context, msg.role, msg.onThinking, msg));
      }
      if (msg.content is String && msg.content.isNotEmpty) {
        contentWidgets.add(messageContent(context, msg.role, msg.content));
      } else if (msg.content is List)
        for (var _content in msg.content) {
          if (GeminiModel.all.contains(widget.model!)) {
            if (_content is GeminiTextContent &&
                _content.text != null &&
                _content.text!.isNotEmpty) {
              contentWidgets
                  .add(messageContent(context, msg.role, _content.text));
            } else if (_content is GeminiPart3) {
              contentWidgets.add(buildArtifact(context, _content.args));
            } else if (_content is GeminiPart1) {
            } else if (_content is GeminiPart2) {}
          } else {
            switch (_content.type) {
              case "text":
                if (_content.text != null && _content.text.isNotEmpty) {
                  if (msg.role == MessageTRole.tool) {
                    if (_content.text.startsWith("{\"google_result")) {
                      //to list gpt google results
                      var results = jsonDecode(_content.text)["google_result"];
                      contentWidgets.add(googleResultList(context, results));
                      isGoogleList = true;
                    }
                  } else {
                    if (_content.text != null && _content.text.isNotEmpty) {
                      contentWidgets.add(
                          messageContent(context, msg.role, _content.text));
                    }
                  }
                }
                break;
              case "image_url":
                break;
              case "tool_use":
                if (_content.name == "save_artifact")
                  contentWidgets.add(buildArtifact(context, _content.input));
                if (_content.name == "webpage_fetch") {
                  final url = _content.input?["url"];
                  if (url?.isNotEmpty ?? false) {
                    contentWidgets.add(messageContent(
                        context, msg.role, _content.input["url"]));
                  }
                }
                break;
              case "tool_result": //only claude
                if (_content.content != null &&
                    _content.content.value.startsWith("{\"google_result")) {
                  //to list claude google results
                  List results =
                      jsonDecode(_content.content.value)["google_result"];
                  contentWidgets.add(googleResultList(context, results));
                  isGoogleList = true;
                } else {
                  // contentWidgets
                  //     .add(messageContent(context, msg.role, "tool test"));
                }
                break;
            }
          }
        }

      for (openai.RunToolCallObject tool in msg.toolCalls) {
        if (!isValidJson(tool.function.arguments))
          contentWidgets.add(messageContent(
            context,
            msg.role,
            tool.function.arguments,
          ));
        switch (tool.function.name) {
          case "save_artifact":
            contentWidgets.add(
                buildArtifact(context, jsonDecode(tool.function.arguments)));
            break;
          case "google_search":
            break;
          case "webpage_fetch":
            var arg = jsonDecode(tool.function.arguments);
            contentWidgets.add(messageContent(context, msg.role, arg["url"]));
            break;
        }
      }
    } catch (e) {
      // contentWidgets
      //     .add(messageContent(context, msg.role, "parse msg error: $e"));
      // isNotEmpty = true;
      Logger.error("parse msg error: $e");
    }
    if (contentWidgets.isNotEmpty) isNotEmpty = true;
    return contentWidgets;
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
    if (func["type"] == null ||
        !supportedContentType.contains(func["type"].toLowerCase())) {
      // return SelectableText(
      //   func["type"] + func["content"],
      //   style: const TextStyle(fontSize: 16.0, color: AppColors.msgText),
      // );
      return contentMarkdown(context, func["content"]);
    }
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      width: artifactWidth + 10,
      height: artifactHight + 50,
      decoration: BoxDecoration(
          // color: Colors.red,
          // border: Border.all(color: ),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Text(func["artifactName"],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: "最小化",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        artifactWidth = Artifact_MIN_W;
                        artifactHight = 5;
                      });
                    },
                    icon: Icon(Icons.minimize),
                  ),
                  IconButton(
                    tooltip: "恢复",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        artifactWidth = Artifact_MIN_W;
                        artifactHight = Artifact_MIN_H;
                      });
                    },
                    icon: Icon(Icons.refresh, size: 18),
                  ),
                  IconButton(
                    tooltip: "最大化",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        artifactWidth = Artifact_MAX_W;
                        artifactHight = Artifact_MAX_H;
                      });
                    },
                    icon: Icon(Icons.maximize, size: 18),
                  ),
                ],
              ),
            ],
          ),
          HtmlContentWidget(
            width: artifactWidth,
            height: artifactHight,
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

  Widget visibilityCopyButton(BuildContext context, String? msg) {
    return Visibility(
        visible: isDisplayDesktop(context) ? _hasCopyIcon : true,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: IconButton(
          tooltip: "Copy",
          onPressed: () {
            Clipboard.setData(ClipboardData(text: msg ?? ""))
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
      return MouseRegion(
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            contentMarkdown(context, _textContent ?? ""),
            visibilityCopyButton(context, _textContent),
          ],
        ),
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
