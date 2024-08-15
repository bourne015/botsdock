import '../models/data.dart';
import '../models/anthropic/schema/schema.dart' as anthropic;
import '../models/openai/schema/schema.dart' as openai;

abstract class Message {
  int? id;
  String role;
  String? name;
  dynamic content; // This can be String, List<Content>, or null
  String? toolCallId;
  List<openai.RunToolCallObject> toolCalls;
  Map<String, Attachment> attachments;
  //sice claude don't support url, we save urls here
  Map<String, VisionFile> visionFiles;
  final int? timestamp;
  bool onThinking = false;
  Message({
    this.id,
    required this.role,
    this.name,
    this.content,
    this.toolCallId,
    List<openai.RunToolCallObject>? toolCalls,
    Map<String, Attachment>? attachments,
    Map<String, VisionFile>? visionFiles,
    this.timestamp,
  })  : attachments = attachments ?? {},
        visionFiles = visionFiles ?? {},
        toolCalls = toolCalls ?? [];

  //save url in object
  void updateImageURL(String url);
  //save url in VisionFiles
  void updateVisionFiles(String filename, String url);
  /**
   * assiatant thread content: string or array
   * no need role in content
   */
  dynamic threadContent();
  /**
   * toDBJson: claude model image save bytes,
   * so toDBJson drop image content
   * and image url saved in visionfiles
   */
  Map<String, dynamic> toDBJson();
  Map<String, dynamic> toJson();

  static Message fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    throw UnimplementedError();
  }
}

class OpenAIMessage extends Message {
  OpenAIMessage({
    int? id,
    required String role,
    String? name,
    dynamic content,
    String? toolCallId,
    List<openai.RunToolCallObject>? toolCalls,
    Map<String, Attachment>? attachments,
    Map<String, VisionFile>? visionFiles,
    final int? timestamp,
    bool? onThinking = false,
  }) : super(
          id: id,
          role: role,
          name: name,
          content: content,
          toolCallId: toolCallId,
          toolCalls: toolCalls,
          attachments: attachments,
          visionFiles: visionFiles,
          timestamp: timestamp,
        );

  //useless in openai case
  @override
  void updateVisionFiles(String filename, String url) {
    visionFiles[filename] = VisionFile(name: filename, url: url);
  }

/**
   * replace image bytes with oss url path
   * for claude: the image could display in message boxs
   * but can't be use for second time
   */
  @override
  void updateImageURL(String ossPath) {
    if (content is List) {
      for (var c in content) {
        if (c.type == "image_url" && !c.imageURL.url.startsWith("https:"))
          c.imageURL.url = ossPath;
      }
    }
  }

  @override
  dynamic threadContent() {
    if (content is List<dynamic>)
      return content.map((e) => e.toJson()).toList();
    else if (content is String) return content;
    return "";
  }

  @override
  Map<String, dynamic> toJson() => {
        'role': role,
        if (name != null) 'name': name,
        if (content != null)
          'content': content is List<dynamic>
              ? content.map((e) => e.toJson()).toList()
              : content,
        if (toolCallId != null) 'tool_call_id': toolCallId,
        if (toolCalls.isNotEmpty)
          'tool_calls': toolCalls.map((tc) => tc.toJson()).toList(),
      };
  @override
  Map<String, dynamic> toDBJson() => {
        'role': role,
        if (name != null) 'name': name,
        if (content != null)
          'content': content is List<dynamic>
              ? content.map((e) => e.toJson()).toList()
              : content,
        if (toolCallId != null) 'tool_call_id': toolCallId,
        if (toolCalls.isNotEmpty)
          'tool_calls': toolCalls.map((tc) => tc.toJson()).toList(),
        if (attachments.isNotEmpty)
          'attachments': attachments
              .map((key, attachment) => MapEntry(key, attachment.toJson())),
        if (visionFiles.isNotEmpty)
          'visionFiles': visionFiles
              .map((key, visionFiles) => MapEntry(key, visionFiles.toJson())),
      };

  static OpenAIMessage fromJson(Map<String, dynamic> json) {
    var role = json['role'];
    var name = json['name'];
    var toolCallId = json['tool_call_id'];
    Map<String, Attachment> attachments = json['attachments'] != null
        ? Map<String, Attachment>.fromEntries(
            (json['attachments'] as Map<String, dynamic>).entries.map((entry) {
            return MapEntry(entry.key, Attachment.fromJson(entry.value));
          }))
        : {};
    Map<String, VisionFile> visionFile = json['visionFiles'] != null
        ? Map<String, VisionFile>.fromEntries(
            (json['visionFiles'] as Map<String, dynamic>).entries.map((entry) {
            return MapEntry(entry.key, VisionFile.fromJson(entry.value));
          }))
        : {};
    dynamic content;
    if (json['content'] != null) {
      if (json['content'] is List) {
        // Assuming list of content parts
        content = (json['content'] as List)
            .map((contentPart) => parseContentPart(contentPart))
            .toList();
      } else if (json['content'] is String) {
        content = json['content'];
      }
    }

    var toolCalls = (json['tool_calls'] as List?)
        ?.map((toolCall) => openai.RunToolCallObject.fromJson(toolCall))
        .toList();
    return OpenAIMessage(
      role: role,
      name: name,
      content: content,
      toolCallId: toolCallId,
      toolCalls: toolCalls,
      attachments: attachments,
      visionFiles: visionFile,
    );
  }
}

class ClaudeMessage extends Message {
  ClaudeMessage({
    int? id,
    required String role,
    dynamic content,
    Map<String, Attachment>? attachments,
    Map<String, VisionFile>? visionFiles,
    final int? timestamp,
    bool? onThinking = false,
  }) : super(
          id: id,
          role: role,
          content: content,
          attachments: attachments,
          visionFiles: visionFiles,
          timestamp: timestamp,
        );

  /**
   * save image oss url in visionFiles
   */
  @override
  void updateVisionFiles(String filename, String url) {
    print("updateVisionFiles: $filename, $url");
    visionFiles[filename] = VisionFile(name: filename, url: url);
  }

  /**
   * replace image bytes with oss url path
   * for claude: the image could display in message boxs
   * but can't be use for second time
   */
  @override
  void updateImageURL(String ossPath) {
    if (content is List) {
      for (var c in content) {
        if (c.type == "image" && !c.source.data.startsWith("https:"))
          c.source.data = ossPath;
      }
    }
  }

  @override
  dynamic threadContent() {
    if (content is List<dynamic>)
      return content.map((e) => e.toJson()).toList();
    else if (content is String) return content;
    return "";
  }

  @override
  Map<String, dynamic> toJson() => {
        'role': role,
        if (content != null)
          'content': content is List<dynamic>
              ? content.map((e) => e.toJson()).toList()
              : content,
      };
  @override
  Map<String, dynamic> toDBJson() => {
        'role': role,
        if (content != null)
          'content': content is List<dynamic>
              ? content
                  .map((e) {
                    if (e.type != "image") return e.toJson();
                  })
                  .where((x) => x != null)
                  .toList()
              : content,
        if (attachments.isNotEmpty)
          'attachments': attachments
              .map((key, attachment) => MapEntry(key, attachment.toJson())),
        if (visionFiles.isNotEmpty)
          'visionFiles': visionFiles
              .map((key, visionFiles) => MapEntry(key, visionFiles.toJson())),
      };

  static ClaudeMessage fromJson(Map<String, dynamic> json) {
    var role = json['role'];

    Map<String, VisionFile> visionFile = json['visionFiles'] != null
        ? Map<String, VisionFile>.fromEntries(
            (json['visionFiles'] as Map<String, dynamic>).entries.map((entry) {
            return MapEntry(entry.key, VisionFile.fromJson(entry.value));
          }))
        : {};
    dynamic content;
    if (json['content'] != null) {
      if (json['content'] is List) {
        // Assuming list of content parts
        content = (json['content'] as List)
            .map((contentPart) => parseContentPart(contentPart))
            .toList();
      } else if (json['content'] is String) {
        content = json['content'];
      }
    }
    return ClaudeMessage(
      role: role,
      content: content,
      visionFiles: visionFile,
    );
  }
}

// Parsing different types of content parts
dynamic parseContentPart(Map<String, dynamic> contentPart) {
  var type = contentPart['type'];
  switch (type) {
    case 'text':
      return TextContent.fromJson(contentPart);
    // return openai.MessageContentTextObject.fromJson(contentPart);
    case 'image_url':
      return openai.MessageContentImageUrlObject.fromJson(contentPart);
    case 'image':
      return anthropic.ImageBlock.fromJson(contentPart);
    case 'image_file':
      return openai.MessageContentImageFileObject.fromJson(contentPart);
    case 'tool_use':
      return anthropic.ToolUseBlock.fromJson(contentPart);
    case 'tool_result':
      return anthropic.ToolResultBlock.fromJson(contentPart);
    default:
      throw Exception('Unsupported content part type: $type');
  }
}
