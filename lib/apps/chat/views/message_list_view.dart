import 'dart:async';

import 'package:botsdock/data/adaptive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/chat.dart';
import 'message_box.dart';
import 'scrollable_positioned_list/lazy_load_scroll_view.dart';

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
              bool isLast = index == 0; //messageLength - 1;
              if (index >= _messageLength) return Offstage();
              var reindex = _messageLength - 1 - index;

              return AnimatedContainer(
                  duration: Duration(milliseconds: 270),
                  padding: isDisplayDesktop(context)
                      ? EdgeInsets.symmetric(horizontal: hval)
                      : EdgeInsets.symmetric(horizontal: 10),
                  child: MessageBox(
                    key: ValueKey(chat.messages[reindex].id),
                    msg: chat.messages[reindex],
                    isLast: isLast,
                    pageId: chat.id,
                    model: chat.model,
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
