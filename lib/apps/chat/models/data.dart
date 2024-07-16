class VisionFile {
  String name;
  String url;
  List<int> bytes;

  VisionFile({
    required this.name,
    this.url = "",
    this.bytes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'bytes': [], //drop bytes
    };
  }

  factory VisionFile.fromJson(Map<String, dynamic> json) {
    return VisionFile(
      name: json['name'],
      url: json['url'],
      bytes: List<int>.from(json['bytes']),
    );
  }
}

/**
 * {"file_id": "", "tools": [{"type": "file_search"}]}
 */
class Attachment {
  String? file_id; //openai file_id
  List<Map<String, String>>? tools;
  bool? downloading;

  Attachment({
    this.file_id = "",
    this.tools = const [],
    this.downloading = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_id': file_id,
      'downloading': downloading,
      'tools': [
        {"type": "code_interpreter"},
        {"type": "file_search"}
      ]
    };
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      file_id: json['file_id'] as String?,
      tools: json['tools'] != null
          ? List<Map<String, String>>.from(
              json['tools'].map((tool) => Map<String, String>.from(tool)))
          : [],
    );
  }
}
