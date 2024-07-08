import 'package:flutter/widgets.dart';

import 'chat.dart';
import 'message.dart';
import '../utils/constants.dart';

//all chat pages
class Pages with ChangeNotifier {
  final Map<int, Chat> _pages = {};
  List<int> _pagesID = [];
  int _currentPageID = -1;

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
    if (newID == null || newID < 0) {
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

  Chat getNthPage(int n) {
    if (n >= _pagesID.length) {
      debugPrint("out of range");
      return _pages[_pagesID[0]]!;
    }
    return _pages[_pagesID[n]]!;
  }

  void setPageTitle(int pageID, String title) {
    _pages[pageID]?.title = title;
    notifyListeners();
  }

  void addMessage(int pageID, Message newMsg) {
    _pages[pageID]?.addMessage(newMsg);
    notifyListeners();
  }

  void appendMessage(int pageID, String newMsg) {
    _pages[pageID]?.appendMessage(newMsg);
    notifyListeners();
  }

  void updateFileUrl(int pageID, int msgId, String url) {
    _pages[pageID]?.updateFileUrl(msgId, url);
  }

  List<Message>? getMessages(int pageID) => _pages[pageID]?.messages;
  List<Widget>? getMessageBox(int pageID) => _pages[pageID]?.messageBox;

  void clearMsg(int pageID) {
    _pages[pageID]?.messages.clear();
    _pages[pageID]?.messageBox.clear();
    notifyListeners();
  }

  void sortPages() {
    //sort pages by page updated_at value
    //sice _pages is map, only keep _pagesID in sorted
    var entries = _pages.entries.toList();
    entries.sort((a, b) => b.value.updated_at.compareTo(a.value.updated_at));
    _pagesID = entries.map((e) => e.key).toList();
  }

  void groupByDate(groupedPages) {
    var today = DateTime.now();
    int dayDiff = 0;

    for (int pid in _pagesID) {
      var pData = "";
      var _page = getPage(pid);
      var _chat_day =
          DateTime.fromMillisecondsSinceEpoch(_page.updated_at * 1000);
      dayDiff = today.difference(_chat_day).inDays.abs();
      if (dayDiff == 0)
        pData = "今天";
      else if (dayDiff == 1)
        pData = "昨天";
      else if (dayDiff >= 2 && dayDiff <= 7)
        pData = "三天前";
      else
        pData = "一周前";

      if (groupedPages[pData] == null) groupedPages[pData] = [];
      groupedPages[pData].add(_page);
    }
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
}
