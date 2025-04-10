import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:botsdock/apps/chat/utils/tools.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';
import 'package:botsdock/apps/chat/vendor/messages/deepseek.dart';
import 'package:botsdock/apps/chat/vendor/messages/gemini.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/utils/prompts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:openai_dart/openai_dart.dart' as openai;
import '../utils/constants.dart';

//model of a chat page
class Chat with ChangeNotifier {
  int _id = -1;
  int? _dbID = -1;
  int? _botID;
  String? _assistantID;
  String? _threadID;
  List<Message> messages = [];

  //tools-gpt: List<openai.ChatCompletionTool>
  //tools-claude: List<anthropic.Tool>
  //tools-claude: List<Map<String, dynamic>>
  List<dynamic> tools = [];
  String toolInputDelta = "";
  List<String> openaiToolInputDelta = [];
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageController.stream;
  int updated_at;

  String _title = "Chat 0";
  String _model = '';
  int tokenSpent = 0;
  bool _onGenerating = false;
  bool doStream = true;
  bool artifact;
  bool internet;
  ItemPosition? position;
  double? _temperature;
  List<StreamSubscription> streamSubscription = [];

  Chat({
    int id = -1,
    int? dbID = -1,
    int? botID,
    String? assistantID,
    String? threadID,
    String title = "Chat 0",
    required String model,
    List<Message>? messages,
    List<dynamic>? tools,
    int? updated_at,
    bool? artifact,
    bool? internet,
    double? temperature,
  })  : _id = id,
        _dbID = dbID,
        _botID = botID,
        _assistantID = assistantID,
        _threadID = threadID,
        _title = title,
        _model = model,
        messages = messages ?? [],
        tools = tools ?? [],
        artifact = artifact ?? false,
        internet = internet ?? false,
        _temperature = temperature,
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

  double? get temperature => _temperature;
  set temperature(double? v) {
    _temperature = v;
    // notifyListeners();
  }

  dynamic getVisionFiles(Map<String, VisionFile> visionFiles, content) {
    if (ClaudeModel.all.contains(model)) {
      visionFiles.forEach((_filename, _visionFile) {
        String _fileType = _filename.split('.').last.toLowerCase();
        String _fileBase64 = base64Encode(_visionFile.bytes);
        var mtype = switch (_fileType) {
          'jpeg' => anthropic.ImageBlockSourceMediaType.imageJpeg,
          'jpg' => anthropic.ImageBlockSourceMediaType.imageJpeg,
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
    } else if (GPTModel.all.contains(model)) {
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
    } else if (GeminiModel.all.contains(model)) {
      visionFiles.forEach((_filename, _visionFile) {
        String _fileType = _filename.split('.').last.toLowerCase();
        var _imgPart = GeminiPart1(
            inlineData: GeminiData1(
          mimeType: 'image/$_fileType',
          data: _visionFile.url,
        ));
        content.add(_imgPart);
      });
    }
  }

  void getAttachments(Map<String, Attachment> attachments, content) {
    if (GeminiModel.all.contains(model)) {
      attachments.forEach((_filename, _attachment) {
        String _fileType = _filename.split('.').last.toLowerCase();
        var mtype = switch (_fileType) {
          'pdf' => "application/pdf",
          "js" => "application/x-javascript",
          "py" => "application/x-python",
          "txt" => "text/plain",
          "HTML" => "text/html",
          "css" => "text/css",
          "md" => "text/md",
          "csv" => "text/csv",
          "xml" => "text/xml",
          "rtf" => "text/rtf",
          _ => throw AssertionError('Unsupported doc type: ${_fileType}'),
        };
        var _filePart = GeminiPart2(
            fileData: GeminiData2(
          mimeType: mtype,
          fileUri: _attachment.file_url,
        ));
        content.add(_filePart);
      });
    } else if (ClaudeModel.all.contains(model)) {
      attachments.forEach((_filename, _attachment) {
        String _fileType = _filename.split('.').last.toLowerCase();
        var mtype = switch (_fileType) {
          'pdf' => "application/pdf",
          _ => throw AssertionError('Unsupported doc type: ${_fileType}'),
        };
        var _source = ClaudeData1(
          type: "base64",
          mediaType: mtype,
          data: _attachment.file_url,
        );
        var _imgContent = ClaudeContent1(type: "document", source: _source);
        content.add(_imgContent);
      });
    }
  }

  int addMessage({
    required String role,
    int? id, //use id if need to insert message with index
    String? text,
    Map<String, VisionFile>? visionFiles,
    Map<String, Attachment>? attachments,
    int? timestamp,
    String? toolCallId,
    anthropic.ToolUseBlock? toolUse,
    anthropic.ToolResultBlock? toolResult,
    GeminiFunctionResponse? geminiFunctionResponse,
  }) {
    var _msg;
    var _content = [];

    if (text != null) {
      if (GeminiModel.all.contains(model))
        _content.add(GeminiTextContent(text: text));
      else
        _content.add(TextContent(text: text));
    }
    if (visionFiles != null) {
      getVisionFiles(visionFiles, _content);
    }
    if (attachments != null) {
      getAttachments(attachments, _content);
    }
    if (toolUse != null) {
      //claude case:save function arguments into the last assistant msg content
      //if the last msg isn't assistant role, add a new assistant msg
      if (messages.last.role == MessageTRole.assistant) {
        (messages.last.content as List).add(toolUse);
        return messages.last.id;
      } else {
        _content.add(toolUse);
      }
    }
    if (toolResult != null) {
      _content.add(toolResult);
    }
    if (geminiFunctionResponse != null) {
      _content.add(geminiFunctionResponse);
    }
    if (ClaudeModel.all.contains(model)) {
      int _newid = messages.isNotEmpty ? (1 + messages.last.id) : 0;
      _msg = ClaudeMessage(
        id: id ?? _newid,
        role: role,
        content: _content,
        visionFiles: visionFiles,
        attachments: attachments,
        timestamp: timestamp,
      );
    } else if (GPTModel.all.contains(model)) {
      int _newid = messages.isNotEmpty ? (1 + messages.last.id) : 0;
      _msg = OpenAIMessage(
        id: id ?? _newid,
        role: role,
        content: _content,
        visionFiles: visionFiles,
        attachments: attachments,
        timestamp: timestamp,
        toolCallId: toolCallId,
      );
    } else if (GeminiModel.all.contains(model)) {
      int _newid = messages.isNotEmpty ? (1 + messages.last.id) : 0;
      _msg = GeminiMessage(
        id: id ?? _newid,
        role: role,
        content: _content,
        visionFiles: visionFiles,
        attachments: attachments,
        timestamp: timestamp,
      );
    } else if (DeepSeekModel.all.contains(model)) {
      int _newid = messages.isNotEmpty ? (1 + messages.last.id) : 0;
      _msg = DeepSeekMessage(
        id: id ?? _newid,
        role: role,
        //deepseek only support text type context for now
        content: text != null ? text : "",
        visionFiles: visionFiles,
        attachments: attachments,
        timestamp: timestamp,
        toolCallId: toolCallId,
      );
    } else if (model == GPTModel.gptv40Dall) {
      int _newid = messages.isNotEmpty ? (1 + messages.last.id) : 0;
      _msg = OpenAIMessage(
        id: id ?? _newid,
        role: role,
        content: text,
        attachments: attachments,
        timestamp: timestamp,
        toolCallId: toolCallId,
      );
    }

    if (id != null && messages.isNotEmpty) {
      //assume that case id == 0
      _msg.id = messages.first.id - 1;
      messages.insert(id, _msg);
    } else
      messages.add(_msg);
    // _messageController.add(_msg);
    doStream = true;
    return messages.length - 1;
  }

  /**
   * excute tools
   */
  Future<dynamic> excuteFunctionCalling({
    required String name,
    Map<String, dynamic>? kwargs,
  }) async {
    late final toolres;
    try {
      switch (name) {
        case "google_search":
          var res = await Tools.google_search(
            query: kwargs?["query"] ?? "",
            num_results: max(1, min(kwargs?["num_results"], 20)),
          );
          toolres = {"google_result": res};
          break;
        case "webpage_fetch":
          var res = await Tools.webpage_query(url: kwargs?["url"] ?? "");
          toolres = {"result": res};
          break;
        case "save_artifact":
          toolres = {"result": "done"};
          break;
        default:
          Logger.warn("tools: ${name} is unsupported");
          toolres = {"result": "true"};
          break;
      }
    } catch (e, s) {
      Logger.error("run tools failed: ${name}, stack: $s");
      toolres = {"result": "error"};
    }
    return toolres;
  }

  /**
   * 1. save function arguments from model into messages
   * 2. excetu function calling
   * 3. save function calling result to tool message inside message-content
   */
  Future<void> handleClaudeToolCall(int index) async {
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

    Map toolres = await excuteFunctionCalling(
      name: name,
      kwargs: {
        "query": input["content"],
        "num_results": input["resultCount"],
        "url": input["url"],
      },
    );

    var _toolID = messages.last.content[index].id;
    addMessage(
        role: MessageTRole.user,
        toolResult: anthropic.ToolResultBlock(
          toolUseId: _toolID,
          isError: false,
          type: "tool_result",
          content: anthropic.ToolResultBlockContent.text(jsonEncode(toolres)),
        ));

    toolInputDelta = "";
  }

  /**
   * save function arguments from model into messages
   * current tools(web search & query) are integrated in Gemini
   * it's no need to excute those tools
   */
  Future<void> handleGeminiToolCall(func) async {
    messages.last.content.last = GeminiPart3(
      name: func.name,
      args: func.args,
    );

    Map toolres = await excuteFunctionCalling(
      name: func.name,
      kwargs: {
        "query": func.args["content"],
        "num_results": func.args["resultCount"],
        "url": func.args["url"],
      },
    );

    addMessage(
      role: MessageTRole.tool,
      geminiFunctionResponse: GeminiFunctionResponse(
        name: func.name,
        response: {"result": toolres["google_result"] ?? toolres["result"]},
      ),
    );
  }

  /**
   * 1. save function arguments from model into messages
   * 2. excetu function calling
   * 3. save function calling result into the same level with message content
   */
  Future<void> handleOpenaiToolCall() async {
    // int _last = messages.length - 1;
    for (int index = 0; index < openaiToolInputDelta.length; index++) {
      //toolcall id
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

    List<openai.RunToolCallObject> _toolcalls = messages.last.toolCalls;
    for (int index = 0; index < _toolcalls.length; index++) {
      var args = jsonDecode(_toolcalls[index].function.arguments);
      Map toolres = await excuteFunctionCalling(
        name: _toolcalls[index].function.name,
        kwargs: {
          "query": args["content"],
          "num_results": args["resultCount"],
          "url": args["url"],
        },
      );

      addMessage(
        role: MessageTRole.tool,
        text: jsonEncode(toolres),
        toolCallId: _toolcalls[index].id,
      );
    }

    openaiToolInputDelta.clear();
  }

  void addMessageContent(dynamic cont) {
    if (messages.last.content is String) {
      ;
    } else if (messages.last.content is List) {
      messages.last.content.add(cont);
    }
  }

  void appendMessage({
    int? index,
    String? msg,
    String? reasoning_content,
    List<openai.ChatCompletionStreamMessageToolCallChunk>? toolCalls,
    dynamic toolUse,
    Map<String, VisionFile>? visionFiles,
    Map<String, Attachment>? attachments,
  }) {
    try {
      if (reasoning_content != null) {
        messages.last.onThinking = true;
        messages.last as DeepSeekMessage
          ..reasoning_content += reasoning_content;
      } else {
        messages.last.onThinking = false;
      }
      if (msg != null && messages.last.content is String)
        messages.last.content += msg;
      else if (msg != null && messages.last.content is List) {
        for (var x in messages.last.content) {
          if (GeminiModel.all.contains(model) && x.text != null)
            x.text += msg;
          else if (!GeminiModel.all.contains(model) && x.type == "text")
            x.text += msg;
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
          messages.last.updateAttachments(name, content);
        });

      if (doStream) _messageController.add(messages.last);
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
      var _asstMsg = messages.firstWhere((x) => x.role == MessageTRole.user);
      if (_asstMsg.content is String)
        return _asstMsg.content;
      else if (_asstMsg.content is List)
        for (var c in _asstMsg.content)
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
    final int pid = c["id"] as int? ?? -1;
    List<Message> _msgs = [];
    if (c["contents"] is List) {
      for (var m in c["contents"]) {
        if (c["model"] is String) {
          if (ClaudeModel.all.contains(c["model"])) {
            _msgs.add(ClaudeMessage.fromJson(m));
          } else if (GPTModel.all.contains(c["model"])) {
            _msgs.add(OpenAIMessage.fromJson(m));
          } else if (c["model"] == GPTModel.gptv40Dall) {
            _msgs.add(OpenAIMessage.fromJson(m));
          } else if (DeepSeekModel.all.contains(c["model"])) {
            _msgs.add(OpenAIMessage.fromJson(m));
          } else if (GeminiModel.all.contains(c["model"])) {
            _msgs.add(GeminiMessage.fromJson(m));
          } else {
            print("Chat fromJson error: unknow model");
          }
        }
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
      artifact: c["artifact"] ?? false,
      internet: c["internet"] ?? false,
      temperature: c["temperature"],
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
        "tools": GeminiModel.all.contains(model)
            ? tools
            : tools.map((e) => e.toJson()).toList(),
        "artifact": artifact,
        "internet": internet,
        "temperature": temperature,
      };

  /**
   * for assistant chat: only send last message
   * since assistant server saved message in thread
   */
  dynamic jsonThreadContent() {
    return messages.last.threadContent();
  }

  /**
   * data for db content column 
   */
  List<dynamic> dbContent() {
    return messages.map((msg) => msg.toDBJson()).toList();
  }

  void clearMessage() {
    if (messages.first.role == MessageTRole.system)
      messages.removeRange(1, messages.length);
    else
      messages.clear();
  }

  void set_function_status(String name, bool status) {
    switch (name) {
      case "save_artifact":
        artifact = status;
        break;
      case "google_search":
        internet = status;
        break;
      case "webpage_fetch":
        break;
      default:
        debugPrint("unsupport tool $name, $status");
        return;
    }
  }

  void addFunctionToGeminiTools(String functionName) {
    var functionToAdd = Functions.all[functionName];
    bool functionDeclarationsExists = false;

    for (var gtool in tools) {
      if (gtool is Map && gtool.containsKey("function_declarations")) {
        functionDeclarationsExists = true;
        List functionDeclarations = gtool["function_declarations"];
        bool functionExists = false;
        for (var existingFunction in functionDeclarations) {
          if (existingFunction["name"] == functionName) {
            functionExists = true;
            break;
          }
        }
        if (!functionExists) functionDeclarations.add(functionToAdd);
        break;
      }
    }

    if (!functionDeclarationsExists) {
      tools.add({
        "function_declarations": [functionToAdd]
      });
    }
  }

  void enable_tool(String name) {
    var funcSchema = Functions.all[name];
    if (GeminiModel.all.contains(model)) {
      // if (name == "google_search") {
      //   bool _exist = tools.any((x) => x.containsKey(name));
      //   if (!_exist) tools.add({name: {}});
      // } else {
      addFunctionToGeminiTools(name);
      // }
    } else if (GPTModel.all.contains(model) ||
        DeepSeekModel.all.contains(model)) {
      var gptTool = openai.ChatCompletionTool.fromJson({
        "type": "function",
        "function": funcSchema,
      });
      bool _exist = tools.any((x) => x.function.name == name);
      if (!_exist) tools.add(gptTool);
    } else if (ClaudeModel.all.contains(model)) {
      var claudeTool = anthropic.Tool.custom(
        name: funcSchema['name'],
        description: funcSchema['description'],
        inputSchema: funcSchema['input_schema'] ?? funcSchema['parameters'],
      );
      bool _exist = tools.any((x) => x.name == name);
      if (!_exist) tools.add(claudeTool);
    }
    set_function_status(name, true);
  }

  void disable_tool(String name) {
    set_function_status(name, false);
    if (GPTModel.all.contains(model) || DeepSeekModel.all.contains(model)) {
      tools.removeWhere((_tool) => _tool.function.name == name);
    } else if (ClaudeModel.all.contains(model)) {
      tools.removeWhere((_tool) => _tool.name == name);
    } else if (GeminiModel.all.contains(model) && tools.isEmpty) {
      // if (name == "google_search") {
      //   tools.removeWhere((gtool) => gtool.containsKey(name));
      // } else {
      for (var gtool in tools) {
        if (gtool.containsKey("function_declarations"))
          gtool["function_declarations"]
              .removeWhere((func) => func["name"] == name);
      }
      // }
    }
  }
}
