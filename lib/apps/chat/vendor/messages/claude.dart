import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/vendor/messages/common.dart';

class ClaudeMessage extends Message {
  ClaudeMessage({
    required int id,
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
        'id': id,
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
    return ClaudeMessage(
      id: id,
      role: role,
      content: content,
      visionFiles: visionFile,
    );
  }
}
