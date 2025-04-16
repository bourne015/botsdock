import 'dart:async';

import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/data/adaptive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:botsdock/apps/chat/models/chat.dart';
import 'message_box.dart';
import 'package:botsdock/apps/chat/views/messages/lazy_load_scroll_view.dart';

class MessageListView extends StatefulWidget {
  final Chat page;
  final bool isDrawerOpen;
  const MessageListView(
      {Key? key, required this.page, required this.isDrawerOpen})
      : super(key: key);

  @override
  State createState() => MessageListViewState();
}

class MessageListViewState extends State<MessageListView> {
  final itemScrollController = ItemScrollController();
  late final ItemPositionsListener _itemPositionListener =
      ItemPositionsListener.create();
  final ValueNotifier<bool> _showScrollToBottom = ValueNotifier(false);
  int _messageLength = 0;
  int _initialScrollIndex = 0;
  double _initialAlignment = 0;

  @override
  void initState() {
    super.initState();
    _itemPositionListener.itemPositions
        .addListener(_handleItemPositionsChanged);
  }

  @override
  void dispose() {
    _itemPositionListener.itemPositions
        .removeListener(_handleItemPositionsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pages pages = Provider.of<Pages>(context, listen: true);
    // Chat chat = pages.currentPage!;
    Chat chat = widget.page;
    _initialScrollIndex = widget.page.position?.index ?? 0;
    _initialAlignment = widget.page.position?.itemLeadingEdge ?? 0;
    // debugPrint("build: ${_initialScrollIndex}, ${_initialAlignment}");
    _messageLength = chat.messages.length;
    double hval = widget.isDrawerOpen ? 100 : 180;
    return Stack(alignment: Alignment.center, children: [
      LazyLoadScrollView(
          scrollOffset: 10,
          onInBetweenOfPage: () {
            _showScrollToBottom.value = true;
          },
          onStartOfPage: () async {
            _showScrollToBottom.value = false;
          },
          onEndOfPage: () async {
            _showScrollToBottom.value = true;
          },
          child: ScrollablePositionedList.builder(
            key: ValueKey(chat.id),
            itemCount: _messageLength,
            itemScrollController: itemScrollController,
            itemPositionsListener: _itemPositionListener,
            initialScrollIndex: _initialScrollIndex,
            initialAlignment: _initialAlignment,
            reverse: true,
            itemBuilder: (context, index) {
              bool isLast = index == 0; //_messageLength - 1;
              if (index >= _messageLength) return Offstage();
              var reindex = _messageLength - 1 - index;
              bool sameRole = false;
              // print("$reindex");
              var currMsgRole = chat.messages[reindex].role;
              if (reindex <= _messageLength - 1 && reindex > 0) {
                var upMsgRole = chat.messages[reindex - 1].role;

                //treat tool message as assistant message
                //openai: tool msg type is 'text', role is 'tool'
                if (upMsgRole == MessageTRole.tool)
                  upMsgRole = MessageTRole.assistant;

                //claude: tool msg type is 'tool_result', role is 'user'
                if (Models.checkORG(chat.model, Organization.anthropic)) {
                  if (upMsgRole == MessageTRole.user) {
                    var _c = chat.messages[reindex - 1].content;
                    if (_c is List &&
                        _c.isNotEmpty &&
                        _c[0].type == "tool_result")
                      upMsgRole = MessageTRole.assistant;
                  }
                  if (currMsgRole == MessageTRole.user) {
                    var _c = chat.messages[reindex].content;
                    if (_c is List &&
                        _c.isNotEmpty &&
                        _c[0].type == "tool_result")
                      currMsgRole = MessageTRole.assistant;
                  }
                }
                if (upMsgRole == currMsgRole &&
                    currMsgRole == MessageTRole.user) sameRole = true;
                if (upMsgRole == currMsgRole &&
                    currMsgRole == MessageTRole.assistant) sameRole = true;
                // print("up:${upMsgRole},  cur: ${chat.messages[reindex].role}");
              }
              if (currMsgRole == MessageTRole.tool) {
                //every tool msg must have a tool_calls msg upside
                //and tool_calls msg won't display in most case
                //so we need to display this tool msg's role-icon
                currMsgRole = MessageTRole.assistant;
                sameRole = false;
              }

              return AnimatedContainer(
                  duration: Duration(milliseconds: 270),
                  padding: isDisplayDesktop(context)
                      ? EdgeInsets.symmetric(horizontal: hval)
                      : EdgeInsets.symmetric(horizontal: 10),
                  child: MessageBox(
                    key: ValueKey(chat.messages[reindex].id),
                    msg: chat.messages[reindex],
                    isLast: isLast,
                    isSameRole: sameRole,
                    pageId: chat.id,
                    model: chat.model,
                    role: currMsgRole,
                    onGenerating: widget.page.onGenerating,
                    messageStream: chat.messageStream,
                  ));
            },
          )),
      ValueListenableBuilder<bool>(
        valueListenable: _showScrollToBottom,
        child: _buildScrollToBottom(context),
        builder: (context, value, child) {
          if (value) {
            return child!;
          }
          return const Offstage();
        },
      ),
    ]);
  }

  Widget _buildScrollToBottom(BuildContext context) {
    return Positioned(
        bottom: 10,
        width: 40,
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.transparent,
          child: const Icon(Icons.keyboard_double_arrow_down),
          onPressed: () async {
            scrollToButtom(duration: const Duration(seconds: 1));
            _showScrollToBottom.value = false;
          },
        ));
  }

  void _handleItemPositionsChanged() {
    ItemPosition? _firstItem =
        _itemPositionListener.itemPositions.value.firstWhereOrNull(
      (position) => position.index == 0,
    );
    ItemPosition? t = _itemPositionListener.itemPositions.value.firstOrNull;
    widget.page.position = t;
    // debugPrint("postion: $t");
    if (_firstItem == null || _firstItem.itemLeadingEdge < -0.2) {
      widget.page.doStream = false;
    } else {
      widget.page.doStream = true;
    }
  }

  Future<void> scrollToButtom(
      {int? index, double? alignment, Duration? duration}) async {
    // Scroll to the end of the list.
    if (itemScrollController.isAttached == true) {
      itemScrollController.scrollTo(
        index: index ?? 0,
        alignment: alignment ?? 0,
        duration: duration ?? const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }
}
