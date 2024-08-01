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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        itemCount: chat.messages.length,
        itemBuilder: (context, index) {
          bool isLast = index == chat.messages.length - 1;
          return MessageBox(
            controller: _scrollController,
            key: ValueKey(chat.messages[index].id),
            msg: chat.messages[index],
            isLast: isLast,
            pageId: pages.currentPageID,
            messageStream: chat.messageStream,
          );
        },
      ),
    );
  }
}
