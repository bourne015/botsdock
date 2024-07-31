import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../utils/global.dart';
import 'chat.dart';
import 'data.dart';
import 'message.dart';
import '../utils/constants.dart';

//all chat pages
class Pages with ChangeNotifier {
  final Map<int, Chat> _pages = {};
  List<int> _pagesID = [];
  int _currentPageID = -1;
  var dio = Dio();

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

  void addMessage(int pageID, Message newMsg) {
    _pages[pageID]?.addMessage(newMsg);
    notifyListeners();
  }

  void appendMessage(int pageID, {String? msg, visionFiles, attachments}) {
    _pages[pageID]?.appendMessage(
        msg: msg, visionFiles: visionFiles, attachments: attachments);
    notifyListeners();
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
      var _date = "";
      var _page = getPage(pid);
      var _chat_day =
          DateTime.fromMillisecondsSinceEpoch(_page.updated_at * 1000);
      dayDiff = today.difference(_chat_day).inDays.abs();
      if (dayDiff == 0)
        _date = "今天";
      else if (dayDiff == 1)
        _date = "昨天";
      else if (dayDiff >= 2 && dayDiff <= 7)
        _date = "三天前";
      else
        _date = "一周前";

      if (!groupedPages.containsKey(_date)) groupedPages[_date] = [];
      groupedPages[_date].add(_page);
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

  void setGeneratingState(int pid, bool state) {
    _pages[pid]!.onGenerating = state;
    notifyListeners();
  }

  Future<void> fetch_pages(user_id) async {
    var chatdbUrl = userUrl + "/" + "${user_id}" + "/chats";
    Response cres = await dio.post(chatdbUrl);
    if (cres.data["result"] == "success") {
      for (var c in cres.data["chats"]) {
        //user dbID to recovery pageID,
        //incase no user log, c["contents"][0]["pageID"] == currentPageID
        var pid = restore_single_page(c);
        Global.saveChats(pid, jsonEncode(c), 0);
        //pid += 1;
      }
      // sortPages();
    }
  }

  int restore_single_page(c) {
    //use db index is to prevent pid duplication
    final pid = c["id"];
    //try {
    addPage(Chat(chatId: pid, title: c["title"]));
    _pages[pid]!.modelVersion = c["model"];
    _pages[pid]!.dbID = c["id"];
    _pages[pid]!.updated_at = c["updated_at"];
    _pages[pid]!.assistantID = c["assistant_id"];
    _pages[pid]!.threadID = c["thread_id"];
    _pages[pid]!.botID = c["bot_id"];
    var msgContent;
    for (var m in c["contents"]) {
      //print("load: $m");
      var smid = m["id"] ?? 0;
      int mid = smid is String ? int.parse(smid) : smid;
      if (MsgType.values[m["type"]] == MsgType.image &&
          m["role"] == MessageTRole.user &&
          m["content"] is List) {
        msgContent = jsonDecode(m["content"]);
      } else
        msgContent = m["content"];

      Map<String, VisionFile> _vfs = {};
      if (m["visionFiles"] != null && m["visionFiles"].isNotEmpty) {
        _vfs = Map<String, VisionFile>.fromEntries(
            (m["visionFiles"] as Map<String, dynamic>).entries.map((entry) {
          return MapEntry(entry.key, VisionFile.fromJson(entry.value));
        }));
      }

      Map<String, Attachment> _afs = {};
      if (m["attachments"] != null && m["attachments"].isNotEmpty) {
        _afs = Map<String, Attachment>.fromEntries(
            (m["attachments"] as Map<String, dynamic>).entries.map((entry) {
          return MapEntry(entry.key, Attachment.fromJson(entry.value));
        }));
      }
      Message msgQ = Message(
          id: mid,
          pageID: pid,
          role: m["role"],
          type: MsgType.values[m["type"]],
          content: msgContent,
          visionFiles: _vfs,
          attachments: _afs,
          timestamp: m["timestamp"]);
      addMessage(pid, msgQ);
    }
    // } catch (error) {
    //   debugPrint("restore_single_page error: ${error}");
    // }
    return pid;
  }

  void reset() {
    _pages.clear();
    _pagesID.clear();
    currentPageID = -1;
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
