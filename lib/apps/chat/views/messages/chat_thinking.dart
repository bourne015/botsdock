import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/vendor/messages/deepseek.dart';
import 'package:botsdock/apps/chat/views/messages/common.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ChatThinkingMessage extends StatefulWidget {
  final DeepSeekMessage msg;

  ChatThinkingMessage({
    Key? key,
    required this.msg,
  });

  @override
  State createState() => ChatThinkingMessageState();
}

class ChatThinkingMessageState extends State<ChatThinkingMessage> {
  bool isExpanded = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            // color: AppColors.thinkingMsgBox,
            borderRadius: BORDERRADIUS15,
          ),
          constraints: const BoxConstraints(minWidth: double.infinity),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thinkingTitle(widget.msg.onThinking),
                thinkingMsg(widget.msg),
              ]),
        ),
        thinkingExpand(),
        thinkingClose(widget.msg),
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
}
