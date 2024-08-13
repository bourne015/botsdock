import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/models/data.dart';

import '../models/anthropic/schema/schema.dart' as anthropic;
import '../models/openai/schema/schema.dart' as openai;
import '../utils/constants.dart';
import 'message.dart';

//model of a chat page
class Chat with ChangeNotifier {
  int _id = -1;
  int? _dbID = -1;
  int? _botID;
  String? _assistantID;
  String? _threadID;
  List<Message> messages = [];
  // dynamic _toolChoice;
  // List<Tool> tools = []; //openai tools
  openai.CreateRunRequestToolChoice? _toolChoice;
  List<openai.ChatCompletionTool> tools = [];
  List<ClaudeTool> claudeTools = []; //claude tools
  String toolInputDelta = "";
  List<String> openaiToolInputDelta = [];
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
    // List<Tool>? tools,
    List<openai.ChatCompletionTool>? tools,
    List<ClaudeTool>? claudeTools,
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
        tools = tools ?? [],
        claudeTools = claudeTools ?? [],
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
        var mtype = switch (_fileType) {
          'jpeg' => anthropic.ImageBlockSourceMediaType.imageJpeg,
          'png' => anthropic.ImageBlockSourceMediaType.imagePng,
          'gif' => anthropic.ImageBlockSourceMediaType.imageGif,
          'webp' => anthropic.ImageBlockSourceMediaType.imageWebp,
          _ =>
            throw AssertionError('Unsupported image MIME type: ${_fileType}'),
        };
        var _source = anthropic.ImageBlockSource(
            type: anthropic.ImageBlockSourceType.base64,
            mediaType: mtype,
            data: _fileBase64);
        var _imgContent = anthropic.ImageBlock(type: "image", source: _source);
        content.add(_imgContent);
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
        var _imgContent = openai.MessageContentImageUrlObject(
            type: "image_url",
            imageUrl: openai.MessageContentImageUrl(url: _imgData));
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
    String? toolCallId,
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
        timestamp: timestamp,
      );
    } else if (model.startsWith("gpt")) {
      _msg = OpenAIMessage(
        id: id ?? messages.length,
        role: role,
        content: _content,
        attachments: attachments,
        timestamp: timestamp,
        toolCallId: toolCallId,
      );
    } else if (model.startsWith("dall")) {
      _msg = OpenAIMessage(
        id: id ?? messages.length,
        role: role,
        content: text,
        attachments: attachments,
        timestamp: timestamp,
        toolCallId: toolCallId,
      );
    }

    messages.add(_msg);
    // _messageController.add(_msg);
    return messages.length - 1;
  }

//add claude tool_use
  void addTool({
    List? toolCalls,
    anthropic.ToolUseBlock? toolUse,
    anthropic.ToolResultBlock? toolResult,
  }) {
    if (toolCalls != null) {
      //openai tool
    }
    if (toolUse != null) {
      //claude tool
      (messages.last.content as List).add(toolUse);
    }
    if (toolResult != null) {
      (messages.last.content as List).add(toolResult);
    }
  }

  /**
   * save claude tool messages output from model to message
   */
  void setClaudeToolInput(int index) {
    var id = (messages.last.content[index] as anthropic.ToolUseBlock).id;
    var name = (messages.last.content[index] as anthropic.ToolUseBlock).name;
    var type = (messages.last.content[index] as anthropic.ToolUseBlock).type;
    Map<String, dynamic> input = jsonDecode(toolInputDelta);
    messages.last.content[index] = anthropic.ToolUseBlock(
      id: id,
      type: type,
      name: name,
      input: input,
    );
    toolInputDelta = "";
  }

  /**
   * save openai tool messages output from model to message
   */
  void setOpenaiToolInput() {
    for (int index = 0; index < openaiToolInputDelta.length; index++) {
      print("setOpenaiToolInput: $openaiToolInputDelta");
      var id = (messages.last.toolCalls[index]).id;
      var type = (messages.last.toolCalls[index]).type;
      var func = (messages.last.toolCalls[index]).function;
      messages.last.toolCalls[index] = openai.RunToolCallObject(
        id: id,
        type: type,
        function: openai.RunToolCallFunction(
          name: func.name,
          arguments: openaiToolInputDelta[index],
        ),
      );
    }

    openaiToolInputDelta.clear();
  }

  void appendMessage({
    int? index,
    String? msg,
    List<openai.ChatCompletionStreamMessageToolCallChunk>? toolCalls,
    dynamic toolUse,
    Map<String, VisionFile>? visionFiles,
    Map<String, Attachment>? attachments,
  }) {
    try {
      if (msg != null && messages.last.content is String)
        messages.last.content += msg;
      else if (msg != null && messages.last.content is List) {
        for (var x in messages.last.content) {
          if (x.type == "text") x.text += msg;
        }
      }
      //openai use toolscalls
      if (toolCalls != null) {
        for (var i = 0; i < toolCalls.length; i++) {
          if (messages.last.toolCalls.length - 1 < toolCalls[i].index) {
            messages.last.toolCalls.add(
              openai.RunToolCallObject(
                id: toolCalls[i].id!,
                type: openai.RunToolCallObjectType.function,
                function: openai.RunToolCallFunction(
                  name: toolCalls[i].function!.name ?? "",
                  arguments: toolCalls[i].function!.arguments ?? "",
                ),
              ),
            );
            openaiToolInputDelta.add(" ");
            openaiToolInputDelta[toolCalls[i].index] +=
                toolCalls[i].function?.arguments ?? "";
          } else {
            openaiToolInputDelta[toolCalls[i].index] +=
                toolCalls[i].function!.arguments ?? "";
          }
        }
      }
      //claude use tool_use
      if (toolUse != null) {
        toolInputDelta += toolUse;
      }

      if (attachments != null)
        attachments.forEach((String name, Attachment content) {
          messages.last.attachments[name] =
              Attachment(file_id: content.file_id, tools: content.tools);
        });

      _messageController.add(messages.last);
    } catch (e) {
      print("appendMessage: $e");
    }
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
      if (msg_id == msg.id) msg.updateImageURL(ossPath);
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
        "tools": tools.map((e) => e.toJson()).toList(),
        "claude_tools": claudeTools.map((e) => e.toJson()).toList(),
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
      if (msg.attachments.isNotEmpty)
        v['attachments'] = msg.attachments
            .map((key, attachment) => MapEntry(key, attachment.toJson()));
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

class ClaudeTool {
  final String name;
  String? description;
  dynamic inputSchema;

  ClaudeTool({required this.name, this.description, required this.inputSchema});
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'input_schema': inputSchema,
    };
  }

  static fromJson(Map<String, dynamic> data) {
    return ClaudeTool(
      name: data['name'],
      description: data['description'],
      inputSchema: data['input_schema'],
    );
  }
}
