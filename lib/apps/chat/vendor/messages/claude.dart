import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;

//this is for file conetent
/**
 * { "type": "document",
    "source": { "type": "base64",
                "media_type": "application/pdf",
                "data": pdf_data},
              "cache_control": {"type": "ephemeral"}
    }
 */
class ClaudeContent1 {
  String? type;
  ClaudeData1? source;
  ClaudeContent1({this.type, this.source});

  factory ClaudeContent1.fromJson(Map<String, dynamic> json) {
    return ClaudeContent1(
      type: json['type'],
      source: ClaudeData1.fromJson(json['source']),
    );
  }

  Map<String, dynamic> toJson() => {"type": type, 'source': source?.toJson()};
}

class ClaudeData1 {
  String? type;
  String? mediaType;
  String? data;
  ClaudeData1({this.type, this.mediaType, required this.data});

  factory ClaudeData1.fromJson(Map<String, dynamic> json) {
    return ClaudeData1(
      type: json["type"],
      mediaType: json['media_type'] ?? "",
      data: json['data'] ?? "",
    );
  }

  Map<String, dynamic> toJson() =>
      {"type": type, 'media_type': mediaType, "data": data};
}

class ClaudeMessage extends Message {
  ClaudeMessage({
    required int id,
    required String role,
    dynamic content,
    Map<String, Attachment>? attachments,
    Map<String, VisionFile>? visionFiles,
    final int? timestamp,
    bool? onProcessing = false,
    bool? onThinking = false,
    ToolStatus? toolstatus = ToolStatus.none,
  }) : super(
          id: id,
          role: role,
          content: content,
          attachments: attachments,
          visionFiles: visionFiles,
          timestamp: timestamp,
          toolstatus: toolstatus,
        );

  /**
   * save image oss url in visionFiles
   */
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
        if (content[i].type == "image" &&
            !content[i].source.data.startsWith('http')) {
          var _source = anthropic.ImageBlockSource(
              type: content[i].source.type,
              mediaType: content[i].source.mediaType,
              data: ossPath);
          content[i] = anthropic.ImageBlock(type: "image", source: _source);
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
        if (content != null)
          'content': content is List<dynamic>
              ? content.map((e) => e.toJson()).toList()
              : content,
      };
  @override
  Map<String, dynamic> toDBJson() => {
        'id': id,
        'role': role,
        if (content != null)
          'content': content is List<dynamic>
              ? content
                  .map((e) {
                    return e.toJson();
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
        if (toolstatus != null) 'toolstatus': toolstatus!.name,
      };

  static ClaudeMessage fromJson(Map<String, dynamic> json) {
    int id = (json['id'] is String)
        ? int.parse(json['id'])
        : (json['id'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
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
    ToolStatus? _toolstatus = null;
    if (json['toolstatus'] is String) {
      String statusString = json['toolstatus'];
      try {
        _toolstatus =
            ToolStatus.values.firstWhere((e) => e.name == statusString);
      } catch (e) {
        _toolstatus = ToolStatus.none;
      }
    }
    return ClaudeMessage(
      id: id,
      role: role,
      content: content,
      visionFiles: visionFile,
      toolstatus: _toolstatus,
    );
  }
}
