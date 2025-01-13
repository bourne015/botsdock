import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';

class GeminiTextContent {
  String? text;
  String? type = 'text';
  GeminiTextContent({required this.text});

  factory GeminiTextContent.fromJson(Map<String, dynamic> json) {
    return GeminiTextContent(
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() => {'text': text};
  Map<String, dynamic> toMap() => {'text': text};
}

class GeminiPart1 {
  GeminiData1? inlineData;
  GeminiPart1({this.inlineData});

  factory GeminiPart1.fromJson(Map<String, dynamic> json) {
    return GeminiPart1(
      inlineData: GeminiData1.fromJson(json['inline_data']),
    );
  }

  Map<String, dynamic> toJson() => {'inline_data': inlineData?.toJson()};
}

class GeminiPart2 {
  GeminiData2? fileData;
  GeminiPart2({this.fileData});

  factory GeminiPart2.fromJson(Map<String, dynamic> json) {
    return GeminiPart2(
      fileData: GeminiData2.fromJson(json['file_data']),
    );
  }

  Map<String, dynamic> toJson() => {'file_data': fileData?.toJson()};
}

class GeminiData1 {
  String? mimeType;
  String? data;
  GeminiData1({this.mimeType, required this.data});

  factory GeminiData1.fromJson(Map<String, dynamic> json) {
    return GeminiData1(
      mimeType: json['mime_type'] ?? "",
      data: json['data'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {'mime_type': mimeType, "data": data};
}

class GeminiData2 {
  String? mimeType;
  String? fileUri;
  GeminiData2({this.mimeType, required this.fileUri});

  factory GeminiData2.fromJson(Map<String, dynamic> json) {
    return GeminiData2(
      mimeType: json['mime_type'] ?? "",
      fileUri: json['file_uri'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {'mime_type': mimeType, "file_uri": fileUri};
}

class GeminiMessage extends Message {
  GeminiMessage({
    required int id,
    required String role,
    String? name,
    dynamic content,
    // String? toolCallId,
    // List<openai.RunToolCallObject>? toolCalls,
    Map<String, Attachment>? attachments,
    Map<String, VisionFile>? visionFiles,
    final int? timestamp,
    bool? onThinking = false,
  }) : super(
          id: id,
          role: role,
          name: name,
          content: content,
          // toolCallId: toolCallId,
          // toolCalls: toolCalls,
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
    // TODO: implement updateAttachments
  }

  /**
   * replace image bytes with oss url path
   */
  @override
  void updateImageURL(String ossPath) {
    if (content is List) {
      for (var i = 0; i < content.length; i++) {
        if (content[i] is GeminiPart1 &&
            !content[i].inlineData.data.startsWith('http')) {
          content[i] = GeminiPart1(
            inlineData: GeminiData1(
                mimeType: content[i].inlineData.mimeType, data: ossPath),
          );
          break;
        }
      }
    }
  }

  @override
  dynamic threadContent() {}

  @override
  Map<String, dynamic> toJson() => {
        'role': role == MessageTRole.user ? 'user' : 'model',
        if (content != null)
          'parts': content is List<dynamic>
              ? content.map((p) => p.toJson()).toList()
              : content,
        // if (toolCallId != null) 'tool_call_id': toolCallId,
        // if (toolCalls.isNotEmpty)
        //   'tool_calls': toolCalls.map((tc) => tc.toJson()).toList(),
      };
  @override
  Map<String, dynamic> toDBJson() => {
        'id': id,
        'role': role == MessageTRole.user ? 'user' : 'model',
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

  static GeminiMessage fromJson(Map<String, dynamic> json) {
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
        content = (json['content'] as List).map((contentPart) {
          if (contentPart.containsKey("text"))
            return GeminiTextContent.fromJson(contentPart);
          else if (contentPart.containsKey("inline_data"))
            return GeminiPart1.fromJson(contentPart);
          else if ((contentPart.containsKey("file_data")))
            return GeminiPart2.fromJson(contentPart);
        }).toList();
      } else if (json['content'] is String) {
        content = json['content'];
      }
    }

    // var toolCalls = (json['tool_calls'] as List?)
    //     ?.map((toolCall) => openai.RunToolCallObject.fromJson(toolCall))
    //     .toList();

    return GeminiMessage(
      id: id,
      role: role,
      name: name,
      content: content,
      // toolCallId: toolCallId,
      // toolCalls: toolCalls,
      attachments: attachments,
      visionFiles: visionFile,
    );
  }
}
