import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/pages.dart';
import './input_field.dart';
import 'message_box.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      messageList(context),
      const ChatInputField(),
    ]);
  }

  Widget messageList(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: true);
    Chat chat = pages.currentPage!;

    return Flexible(
      child: ListView.builder(
        key: ValueKey(chat.id),
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          bool isLast = index == chat.messages.length - 1;
          // return chat.messageBox[index];
          return MessageBox(
            key: UniqueKey(),
            msg: chat.messages[index],
            isLast: isLast,
            pageId: pages.currentPageID,
          );
        },
        itemCount: chat.messages.length,
      ),
    );
  }
}
