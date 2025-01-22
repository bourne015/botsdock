import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';
import 'package:openai_dart/openai_dart.dart' as openai;

class DeepSeekMessage extends Message {
  DeepSeekMessage({
    required int id,
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

  @override
  void updateAttachments(String filename, Attachment content) {
    attachments[filename] = Attachment(
      file_id: content.file_id,
      tools: content.tools,
    );
  }

  /**
   * replace image bytes with oss url path
   */
  @override
  void updateImageURL(String ossPath) {
    if (content is List) {
      for (var i = 0; i < content.length; i++) {
        if (content[i].type == "image_url" &&
            !content[i].imageUrl.url.startsWith('http')) {
          content[i] = openai.MessageContentImageUrlObject(
              type: "image_url",
              imageUrl: openai.MessageContentImageUrl(url: ossPath));
          break;
        }
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
        'id': id,
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

  static DeepSeekMessage fromJson(Map<String, dynamic> json) {
    int id = (json['id'] is String)
        ? int.parse(json['id'])
        : (json['id'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
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
    return DeepSeekMessage(
      id: id,
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
