import 'dart:convert';

import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

import '../utils/global.dart';
import 'chat.dart';

//all chat pages
class Pages with ChangeNotifier {
  final Map<int, Chat> _pages = {};
  final flattenedPages = <dynamic>[];
  List<int> _pagesID = [];
  int _currentPageID = -1;
  var chatApi = ChatAPI();

  void set_artifact(int pid, bool v) {
    getPage(pid).artifact = v;
    notifyListeners();
  }

  void set_internet(int pid, bool v) {
    getPage(pid).internet = v;
    notifyListeners();
  }

  set currentPageID(int cid) {
    _currentPageID = cid;
    notifyListeners();
  }

  int get currentPageID => _currentPageID;

  Chat? get currentPage {
    if (currentPageID >= 0) {
      return _pages[_currentPageID]!;
    } else {
      return null;
    }
  }

  int get pagesLen => _pages.length;

  int assignNewPageID() {
    for (var i = 1; i < 1000; i++) {
      if (!_pagesID.contains(i)) return i;
    }
    return _pagesID.length + 1;
  }

  int addPage(Chat newChat, {bool sort = false}) {
    int? newID = newChat.id;
    if (newID < 0) {
      newID = assignNewPageID();
      newChat.id = newID;
    }
    //_currentPageID = newID;
    _pages[newID] = newChat;
    _pagesID.add(newID);
    if (sort) {
      sortPages();
      flattenPages();
    }
    notifyListeners();
    return newID;
  }

  void delPage(int pageID) {
    _pages.remove(pageID);
    _pagesID.remove(pageID);
    notifyListeners();
  }

  Chat getPage(int pageID) => _pages[pageID]!;

  void setPageTitle(int pageID, String title) {
    _pages[pageID]?.title = title;
    notifyListeners();
  }

  bool getPageGenerateStatus(int pageId) {
    return _pages[pageId]?.onGenerating ?? false;
  }

  void setPageGenerateStatus(int pageID, bool status) {
    _pages[pageID]?.onGenerating = status;
    notifyListeners();
  }

  List<Message>? getMessages(int pageID) => _pages[pageID]?.messages;

  void clearCurrentPage() {
    currentPage!.clearMessage();
    notifyListeners();
  }

  void sortPages() {
    //sort pages by page updated_at value
    //sice _pages is map, only keep _pagesID in sorted
    var entries = _pages.entries.toList();
    entries.sort((a, b) => b.value.updated_at.compareTo(a.value.updated_at));
    _pagesID = entries.map((e) => e.key).toList();
  }

  /**
   * group pages by date
   */
  void flattenPages() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final _groups = [
      PageGroup(label: '今天', date: today),
      PageGroup(label: '昨天', date: yesterday),
      PageGroup(label: '三天前', date: threeDaysAgo),
      PageGroup(label: '七天前', date: sevenDaysAgo),
    ];
    // final flattenedList = <dynamic>[];
    flattenedPages.clear();
    for (final _pid in _pagesID) {
      var _page = getPage(_pid);
      final pageDate =
          DateTime.fromMillisecondsSinceEpoch(_page.updated_at * 1000);
      int dayDiff = today.difference(pageDate).inDays.abs();
      if (dayDiff == 0)
        _groups[0].pages.add(_page);
      else if (dayDiff == 1)
        _groups[1].pages.add(_page);
      else if (dayDiff >= 2 && dayDiff <= 7)
        _groups[2].pages.add(_page);
      else
        _groups[3].pages.add(_page);
    }
    for (var _group in _groups) {
      if (_group.pages.isNotEmpty) {
        flattenedPages.add(_group.label);
        flattenedPages.addAll(_group.pages);
      }
    }

    // return flattenedList;
  }

  /**
   * search for target bot
   */
  int checkBot(int bot_id) {
    for (var entry in _pages.entries) {
      var _pid = entry.key;
      var _chatpage = entry.value;
      if (_chatpage.botID == bot_id) {
        return _pid;
      }
    }
    return -1;
  }

  /**
   * search for cat assistant by assistant id
   */
  int checkCat(String ass_id) {
    for (var entry in _pages.entries) {
      var _pid = entry.key;
      var _chatpage = entry.value;
      if (_chatpage.assistantID == ass_id) {
        return _pid;
      }
    }
    return -1;
  }

  void setGeneratingState(int pid, bool state) {
    _pages[pid]!.onGenerating = state;
    notifyListeners();
  }

  Future<void> fetch_pages(user_id) async {
    try {
      var chatData = await chatApi.chats(user_id);
      for (var c in chatData) {
        //user dbID to recovery pageID,
        //incase no user log, c["contents"][0]["pageID"] == currentPageID
        //var pid = restore_single_page(c);
        addPage(Chat.fromJson(c));
        Global.saveChats(user_id, c["id"], jsonEncode(c), 0);
        //pid += 1;
      }
      // sortPages();
    } catch (e) {
      print('Error fetching pages: $e');
    }
  }

  void reset() {
    _pages.clear();
    _pagesID.clear();
    flattenedPages.clear();
    currentPageID = -1;
    notifyListeners();
  }
}

class PageGroup {
  final String label;
  final DateTime? date;
  final List<Chat> pages = [];

  PageGroup({required this.label, this.date});

  // String get dateLabel => '$label (${DateFormat('MM-dd').format(date)})';
  String get dateLabel => '$label';
}

class PropertyState {
  final String initModelVersion;
  final bool isDrawerOpen;
  final bool onInitPage;
  final bool isLoading;

  const PropertyState({
    required this.initModelVersion,
    required this.isDrawerOpen,
    required this.onInitPage,
    required this.isLoading,
  });

  PropertyState copyWith({
    String? initModelVersion,
    bool? isDrawerOpen,
    bool? onInitPage,
    bool? isLoading,
  }) {
    return PropertyState(
      initModelVersion: initModelVersion ?? this.initModelVersion,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      onInitPage: onInitPage ?? this.onInitPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// StateNotifier
class PropertyNotifier extends rp.StateNotifier<PropertyState> {
  PropertyNotifier()
      : super(PropertyState(
          initModelVersion: DefaultModelVersion.id,
          isDrawerOpen: true,
          onInitPage: true,
          isLoading: false,
        ));

  void setInitModelVersion(String value) {
    state = state.copyWith(initModelVersion: value);
  }

  void setIsDrawerOpen(bool value) {
    state = state.copyWith(isDrawerOpen: value);
  }

  void setIsLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setOnInitPage(bool value) {
    state = state.copyWith(onInitPage: value);
  }

  void reset() {
    state = PropertyState(
      initModelVersion: DefaultModelVersion.id,
      isDrawerOpen: true,
      onInitPage: true,
      isLoading: false,
    );
  }
}

// Provider
final propertyProvider =
    rp.StateNotifierProvider<PropertyNotifier, PropertyState>((ref) {
  return PropertyNotifier();
});
