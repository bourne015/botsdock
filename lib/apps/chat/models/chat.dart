import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/models/data.dart';

import '../utils/constants.dart';
import 'claude_data.dart';
import 'message.dart';
import 'openai_data.dart';

//model of a chat page
class Chat with ChangeNotifier {
  int _id = -1;
  int? _dbID = -1;
  int? _botID;
  String? _assistantID;
  String? _threadID;
  List<Message> messages = [];
  dynamic _toolChoice;
  List<Tool>? _tools;
  StreamOptions? _streamOptions;
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageController.stream;
  int updated_at;

  String _title = "Chat 0";
  String _model = '';
  int tokenSpent = 0;
  bool _onGenerating = false;

  Chat({
    int id = -1,
    int? dbID = -1,
    int? botID,
    String? assistantID,
    String? threadID,
    String title = "Chat 0",
    required String model,
    List<Message>? messages,
    StreamOptions? streamOptions,
    dynamic toolChoice,
    List<Tool>? tools,
    int? updated_at,
  })  : _id = id,
        _dbID = dbID,
        _botID = botID,
        _assistantID = assistantID,
        _threadID = threadID,
        _title = title,
        _model = model,
        messages = messages ?? [],
        _streamOptions = streamOptions,
        _toolChoice = toolChoice,
        _tools = tools,
        updated_at =
            updated_at ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  int get id => _id;
  set id(int v) {
    _id = v;
  }

  String get model => _model;

  set model(String? v) {
    _model = v!;
  }

  String get title => _title;
  set title(String v) {
    _title = v;
  }

  int? get dbID => _dbID;
  set dbID(int? v) {
    _dbID = v;
  }

  int? get botID => _botID;
  set botID(int? v) {
    _botID = v;
  }

  String? get assistantID => _assistantID;
  set assistantID(String? v) {
    _assistantID = v;
  }

  String? get threadID => _threadID;
  set threadID(String? v) {
    _threadID = v;
  }

  bool get onGenerating => _onGenerating;
  set onGenerating(bool v) {
    _onGenerating = v;
  }

  dynamic getVisionFiles(Map<String, VisionFile> visionFiles, content) {
    if (model.startsWith("claude")) {
      visionFiles.forEach((_filename, _visionFile) {
        String _fileType = _filename.split('.').last.toLowerCase();
        String _fileBase64 = base64Encode(_visionFile.bytes);
        var _source = Source(
            type: "base64", mediaType: 'image/$_fileType', data: _fileBase64);
        var _imgContent = ClaudeImageContent(source: _source);
        content.add(_imgContent);
        print("getVisionFiles: mt: ${_source.mediaType}");
      });
    } else {
      visionFiles.forEach((_filename, _visionFile) {
        var _imgData = "";
        if (_visionFile.url.isNotEmpty)
          _imgData = _visionFile.url;
        else if (_visionFile.bytes.isNotEmpty) {
          String _fileType = _filename.split('.').last.toLowerCase();
          String _fileBase64 = base64Encode(_visionFile.bytes);
          _imgData = "data:image/$_fileType;base64,$_fileBase64";
        }
        var _imgContent = ImageUrlContent(imageURL: ImageURL(url: _imgData));
        content.add(_imgContent);
      });
    }
  }

  int addMessage({
    required String role,
    int? id,
    String? text,
    Map<String, VisionFile> visionFiles = const {},
    Map<String, Attachment> attachments = const {},
    int? timestamp,
  }) {
    var _msg;
    var _content = [];
    if (visionFiles.isNotEmpty) getVisionFiles(visionFiles, _content);
    if (text != null) {
      var _textContent = TextContent(text: text);
      _content.add(_textContent);
    }

    if (model.startsWith("claude")) {
      _msg = ClaudeMessage(
        id: id ?? messages.length,
        role: role,
        content: _content,
        attachments: attachments,
        // visionFiles: visionFiles,
        timestamp: timestamp,
      );
    } else {
      _msg = OpenAIMessage(
        id: id ?? messages.length,
        role: role,
        content: _content,
        attachments: attachments,
        // visionFiles: visionFiles,
        timestamp: timestamp,
      );
    }

    messages.add(_msg);
    // _messageController.add(_msg);
    return messages.length - 1;
  }

  void appendMessage(
      {String? msg,
      Map<String, VisionFile>? visionFiles,
      Map<String, Attachment>? attachments}) {
    int lastMsgID = messages.isNotEmpty ? messages.length - 1 : 0;
    if (messages[lastMsgID].content is String)
      messages[lastMsgID].content += msg;
    else if (messages[lastMsgID].content is List) {
      //assume the last one is text content
      //TODO: optimize
      for (var x in messages[lastMsgID].content) {
        if (x.type == "text") x.text += msg;
      }
    }

    // if (visionFiles != null && visionFiles.isNotEmpty)
    //   visionFiles.forEach((String name, VisionFile content) {
    //     messages[lastMsgID].visionFiles[name] = VisionFile(
    //         name: content.name, url: content.url, bytes: content.bytes);
    //   });
    if (attachments != null)
      attachments.forEach((String name, Attachment content) {
        messages[lastMsgID].attachments![name] =
            Attachment(file_id: content.file_id, tools: content.tools);
      });

    _messageController.add(messages.last);
  }

  String contentforTitle() {
    if (model == GPTModel.gptv40Dall) {
      if (messages.first.content is String)
        return messages.first.content;
      else if (messages.first.content is List)
        return messages.first.content.first.text;
    } else {
      if (messages[1].content is String)
        return messages[1].content;
      else if (messages[1].content is List)
        for (var c in messages[1].content)
          if (c.type == 'text')
            return c.text.length > 1000 ? c.text.substring(0, 1000) : c.text;
    }
    return "";
  }

/**
 * after display image, the image will uploade to oss
 * then oss url should replace image bytes
 * only openai
 * claude don't support url image
 */
  void updateVision(int msg_id, String imageName, String ossPath) {
    for (var msg in messages) {
      if (msg_id == msg.id) {
        // msg.visionFiles[imageName]!.url = ossPath;
        // msg.visionFiles[imageName]!.bytes = [];
        msg.updateImageURL(ossPath);
      }
    }
  }

  static Chat fromJson(c) {
    //use db index is to prevent pid duplication
    final pid = c["id"];
    List<Message> _msgs = [];
    for (var m in c["contents"]) {
      if (c["model"].startsWith("claude")) {
        _msgs.add(ClaudeMessage.fromJson(m));
      } else if (c["model"].startsWith("gpt")) {
        _msgs.add(OpenAIMessage.fromJson(m));
      } else {
        print("Chat fromJson error: unknow model");
      }
    }
    return Chat(
      id: pid,
      dbID: c["id"],
      updated_at: c["updated_at"],
      assistantID: c["assistant_id"],
      threadID: c["thread_id"],
      botID: c["bot_id"],
      title: c["title"],
      model: c["model"],
      messages: _msgs,
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  /**
   * data for chat completetion
   */
  List<dynamic> jsonMessages() {
    return messages.map((msg) => msg.toJson()).toList();
  }

  dynamic jsonThreadContent() {
    return messages.last.threadContent();
  }

  /**
   * data for db content column 
   */
  List<dynamic> dbContent() {
    return messages.map((msg) {
      var v = msg.toDBJson();
      if (msg.attachments!.isNotEmpty)
        v['attachments'] = msg.attachments
            ?.map((key, attachment) => MapEntry(key, attachment.toJson()));
      return v;
    }).toList();
  }
}

class StreamOptions {
  final bool? includeUsage;

  StreamOptions({this.includeUsage});

  factory StreamOptions.fromJson(Map<String, dynamic> json) {
    return StreamOptions(includeUsage: json['include_usage']);
  }

  Map<String, dynamic> toJson() {
    return {
      if (includeUsage != null) 'include_usage': includeUsage,
    };
  }
}

class ToolChoice {
  final String type;
  final FunctionObject function;

  ToolChoice({required this.type, required this.function});

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
  factory ToolChoice.fromJson(Map<String, dynamic> json) {
    return ToolChoice(
      type: json['type'],
      function: FunctionObject.fromJson(json['function']),
    );
  }
  static bool isValid(dynamic json) {
    return json is Map<String, dynamic> &&
        json.containsKey('type') &&
        json.containsKey('function');
  }
}

class Tool {
  final String type;
  final FunctionObject function;

  Tool({required this.type, required this.function});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      type: json['type'],
      function: FunctionObject.fromJson(json['function']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'function': function.toJson(),
    };
  }
}
