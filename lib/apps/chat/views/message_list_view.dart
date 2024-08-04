import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/pages.dart';
import 'message_box.dart';
import './scrollable_positioned_list/scrollable_positioned_list.dart';
import './scrollable_positioned_list/lazy_load_scroll_view.dart';

class MessageListView extends StatefulWidget {
  const MessageListView({Key? key}) : super(key: key);

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
    Pages pages = Provider.of<Pages>(context, listen: true);
    Chat chat = pages.currentPage!;

    _messageLength = chat.messages.length;
    return Stack(alignment: Alignment.center, children: [
      LazyLoadScrollView(
          scrollOffset: 10,
          onPageScrollStart: () {},
          onPageScrollEnd: () {
            // _userScrolling = false;
          },
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
            initialAlignment: 0,
            reverse: true,
            itemBuilder: (context, index) {
              bool isLast = index == 0; //messageLength - 1;

              if (index >= _messageLength) return Offstage();
              var reindex = _messageLength - 1 - index;

              return MessageBox(
                key: ValueKey(chat.messages[reindex].id),
                msg: chat.messages[reindex],
                isLast: isLast,
                pageId: pages.currentPageID,
                messageStream: chat.messageStream,
              );
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
          child: Icon(Icons.keyboard_double_arrow_down),
          onPressed: () async {
            scrollToButtom(duration: const Duration(seconds: 1));
            _showScrollToBottom.value = false;
          },
        ));
  }

  void _handleItemPositionsChanged() {
    // final _itemPositions = _itemPositionListener.itemPositions.value.toList();
    // print("itemPositions: ${_itemPositions.map((e) => e.index).toList()}");
    // if (!_userScrolling) scrollToButtom();
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
