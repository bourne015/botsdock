import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/views/messages/common.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatTextMessage extends StatefulWidget {
  final String? role;
  final String text;

  ChatTextMessage({
    Key? key,
    this.role,
    required this.text,
  });

  @override
  State createState() => ChatTextMessageState();
}

class ChatTextMessageState extends State<ChatTextMessage> {
  bool _hasCopyIcon = false;

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
    if (widget.role == MessageTRole.user) {
      return SelectableText(widget.text, maxLines: null);
    } else {
      return MouseRegion(
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            contentMarkdown(context, widget.text),
            visibilityCopyButton(context, widget.text),
          ],
        ),
      );
    }
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
}
