import 'dart:convert';

import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';
import 'package:botsdock/apps/chat/vendor/messages/deepseek.dart';
import 'package:botsdock/apps/chat/vendor/messages/gemini.dart';
import 'package:botsdock/apps/chat/views/messages/chat_tool.dart';
import 'package:botsdock/apps/chat/views/messages/chat_file.dart';
import 'package:botsdock/apps/chat/views/messages/chat_image.dart';
import 'package:botsdock/apps/chat/views/messages/chat_text.dart';
import 'package:botsdock/apps/chat/views/messages/chat_thinking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:url_launcher/url_launcher.dart';

import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';

class MessageBox extends rp.ConsumerStatefulWidget {
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
  rp.ConsumerState createState() => MessageBoxState();
}

class MessageBoxState extends rp.ConsumerState<MessageBox> {
  late final ScrollController _attachmentscroll;
  late final ScrollController _visionFilescroll;
  late final Stream<Message> _messageStream;
  bool isGoogleList = false;
  bool isNotEmpty = false;
  bool expandedSearchResults = false;

  @override
  void initState() {
    super.initState();
    _attachmentscroll = ScrollController();
    _visionFilescroll = ScrollController();
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

  Widget resultExpandButton(BuildContext context) {
    return IconButton(
        tooltip: expandedSearchResults ? "收起" : "展开",
        visualDensity: VisualDensity.compact,
        onPressed: () {
          setState(() {
            expandedSearchResults = !expandedSearchResults;
          });
        },
        icon: Icon(expandedSearchResults
            ? Icons.keyboard_double_arrow_right
            : Icons.keyboard_double_arrow_left));
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
            maxWidth: expandedSearchResults
                ? resultIcon_W / 1.5
                : !isDisplayDesktop(context)
                    ? resultIcon_W
                    : resultIconExpand_W,
          ),
          // width: expandSearchResults ? resultIcon_W : resultIconExpand_W,
          // height: resultIcon_H,
          decoration: BoxDecoration(
            // color: AppColors.userMsgBox,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
              // isThreeLine: isDisplayDesktop(context) && expandedSearchResults
              //     ? true
              //     : false,
              dense: true,
              leading: expandedSearchResults
                  ? null
                  : CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage("assets/images/google.png"),
                      radius: 12,
                    ),
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              title: isDisplayDesktop(context)
                  ? Text("搜索结果", overflow: TextOverflow.clip, maxLines: 1)
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
              trailing: resultExpandButton(context)),
        ),
        AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: card_w,
            height: expandedSearchResults ? card_h : 1,
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              // color: AppColors.userMsgBox,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: CarouselView(
              itemSnapping: true,
              shrinkExtent: 100,
              scrollDirection: Axis.horizontal,
              itemExtent: resultCard_W,
              // backgroundColor: AppColors.userMsgBox,
              shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS15),
              // padding: EdgeInsets.all(20),
              onTap: (i) {
                launchUrl(Uri.parse(results[i]["link"]));
              },
              children: results.map((x) {
                return Card(
                  // color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS15),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
                                  // style: TextStyle(fontSize: 10.5),
                                  style: Theme.of(context).textTheme.labelSmall,
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
            ))
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
    User user = ref.watch(userProvider);
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
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.surface,
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
        contentWidgets.add(
          ChatImageMessage(images: msg.visionFiles),
        );
      }
      if (msg.attachments.isNotEmpty) {
        contentWidgets.add(
          ChatfileMessage(files: msg.attachments, model: widget.model),
        );
      }
      if (widget.isLast &&
          msg is DeepSeekMessage &&
          msg.reasoning_content.isNotEmpty) {
        contentWidgets.add(ChatThinkingMessage(msg: msg));
      }
      if (msg.content is String && msg.content.isNotEmpty) {
        contentWidgets.add(ChatTextMessage(role: msg.role, text: msg.content));
      } else if (msg.content is List)
        for (var _content in msg.content) {
          if (Models.checkORG(widget.model!, Organization.google)) {
            if (_content is GeminiTextContent &&
                _content.text != null &&
                _content.text!.isNotEmpty) {
              contentWidgets.add(
                  ChatTextMessage(role: msg.role, text: _content.text ?? ""));
            } else if (_content is GeminiPart3) {
              contentWidgets.add(ChatToolMessage(
                toolName: _content.name ?? "",
                // descriping: url,
                status: msg.toolstatus,
              ));
              if (_content.name == "save_artifact")
                contentWidgets
                    .add(ChatArtifactMessage(function: _content.args));
            } else if (_content is GeminiPart1) {
            } else if (_content is GeminiPart2) {
            } else if (_content is GeminiFunctionResponse) {
              if (_content.name == "google_search") {
                var results = _content.response?["result"];
                contentWidgets.add(googleResultList(context, results));
                isGoogleList = true;
              }
            }
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
                          ChatTextMessage(role: msg.role, text: _content.text));
                    }
                  }
                }
                break;
              case "image_url":
                break;
              case "tool_use":
                var desc = "";
                if (_content.name == "webpage_fetch") {
                  desc = _content.input?["url"];
                }
                contentWidgets.add(ChatToolMessage(
                  id: _content.id,
                  toolName: _content.name,
                  descriping: desc,
                  status: msg.toolstatus,
                ));
                if (_content.name == "save_artifact")
                  contentWidgets
                      .add(ChatArtifactMessage(function: _content.input));

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
        contentWidgets.add(ChatToolMessage(
          id: tool.id,
          toolName: tool.function.name,
          // descriping: arg["url"],
          status: msg.toolstatus,
        ));
        if (!isValidJson(tool.function.arguments)) {
          continue;
        }
        switch (tool.function.name) {
          case "save_artifact":
            contentWidgets.add(ChatArtifactMessage(
                function: jsonDecode(tool.function.arguments)));
            break;
          case "google_search":
            break;
          case "webpage_fetch":
            // var arg = jsonDecode(tool.function.arguments);
            break;
        }
      }
    } catch (e, s) {
      // contentWidgets
      //     .add(messageContent(context, msg.role, "parse msg error: $e"));
      // isNotEmpty = true;
      Logger.error("parse msg error: $e, $s");
    }
    if (contentWidgets.isNotEmpty) isNotEmpty = true;
    return contentWidgets;
  }

  bool isValidJson(String jsonString) {
    try {
      json.decode(jsonString);
      return true;
    } on FormatException catch (e) {
      Logger.warn("invalid json: $e");
      return false;
    }
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
}
