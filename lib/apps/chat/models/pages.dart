import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../utils/global.dart';
import 'chat.dart';
import 'message.dart';
import '../utils/constants.dart';

//all chat pages
class Pages with ChangeNotifier {
  final Map<int, Chat> _pages = {};
  List<int> _pagesID = [];
  int _currentPageID = -1;
  late final Dio _dio;

  Pages() {
    _dio = Dio();
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
    if (sort) sortPages();
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

  void clearMsg(int pageID) {
    _pages[pageID]?.messages.clear();

    notifyListeners();
  }

  void sortPages() {
    //sort pages by page updated_at value
    //sice _pages is map, only keep _pagesID in sorted
    var entries = _pages.entries.toList();
    entries.sort((a, b) => b.value.updated_at.compareTo(a.value.updated_at));
    _pagesID = entries.map((e) => e.key).toList();
  }

  List<dynamic> flattenPages() {
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
    final flattenedList = <dynamic>[];
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
        flattenedList.add(_group.label);
        flattenedList.addAll(_group.pages);
      }
    }

    return flattenedList;
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

  void setGeneratingState(int pid, bool state) {
    _pages[pid]!.onGenerating = state;
    notifyListeners();
  }

  Future<void> fetch_pages(user_id) async {
    var chatdbUrl = USER_URL + "/" + "${user_id}" + "/chats";
    try {
      Response cres = await _dio.post(chatdbUrl);
      if (cres.data["result"] == "success") {
        for (var c in cres.data["chats"]) {
          //user dbID to recovery pageID,
          //incase no user log, c["contents"][0]["pageID"] == currentPageID
          //var pid = restore_single_page(c);
          addPage(Chat.fromJson(c));
          Global.saveChats(c["id"], jsonEncode(c), 0);
          //pid += 1;
        }
        // sortPages();
      }
    } catch (e) {
      print('Error fetching pages: $e');
    }
  }

  void reset() {
    _pages.clear();
    _pagesID.clear();
    currentPageID = -1;
    notifyListeners();
  }
}

class Property with ChangeNotifier {
  String _initModelVersion = DefaultModelVersion;
  bool _isDrawerOpen = true;
  bool _onInitPage = true;
  bool _isLoading = true;

  String get initModelVersion => _initModelVersion;

  set initModelVersion(String? v) {
    _initModelVersion = v!;
    notifyListeners();
  }

  bool get isDrawerOpen => _isDrawerOpen;
  set isDrawerOpen(bool v) {
    _isDrawerOpen = v;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  set isLoading(bool val) {
    _isLoading = val;
    //notifyListeners();
  }

  bool get onInitPage => _onInitPage;
  set onInitPage(bool val) {
    _onInitPage = val;
    notifyListeners();
  }

  void reset() {
    _initModelVersion = DefaultModelVersion;
    _isDrawerOpen = true;
    _onInitPage = true;
    _isLoading = true;
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
