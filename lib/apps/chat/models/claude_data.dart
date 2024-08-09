import 'data.dart';

class ClaudeImageContent {
  String type = 'image';
  Source source;

  ClaudeImageContent({required this.source});

  Map<String, dynamic> toJson() => {
        'type': type,
        'source': source.toJson(),
      };

  static ClaudeImageContent fromJson(Map<String, dynamic> json) {
    return ClaudeImageContent(source: Source.fromJson(json['source']));
  }
}

class Source {
  String type; // Example: "base64"
  String mediaType;
  String data;

  Source({required this.type, required this.mediaType, required this.data});

  Map<String, dynamic> toJson() => {
        'type': type,
        'media_type': mediaType,
        'data': data,
      };

  static Source fromJson(Map<String, dynamic> json) {
    return Source(
        type: json['type'], mediaType: json['mediaType'], data: json['data']);
  }
}

class ToolUse {
  final String type = 'tool_use';
  final String id;
  final String name;
  final Map<String, dynamic> input;
  ToolUse({required this.id, required this.name, required this.input});

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        'input': input,
      };

  factory ToolUse.fromJson(Map<String, dynamic> json) {
    return ToolUse(
      id: json['id'],
      name: json['name'],
      input: json['input'],
    );
  }
}

/**
 * Claude ToolResult content
 */
class ToolResult {
  String type = 'tool_result';
  String toolUseId;
  bool isError;
  List<dynamic> content;

  ToolResult({
    required this.toolUseId,
    required this.isError,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'toolUseId': toolUseId,
        'isError': isError,
        'content': content.map((c) => c.toJson()).toList(),
      };

  static ToolResult fromJson(Map<String, dynamic> json) {
    return ToolResult(
      toolUseId: json['toolUseId'],
      isError: json['isError'],
      content: (json['content'] as List)
          .map((item) => parseToolResultContent(item))
          .toList(),
    );
  }
}

dynamic parseToolResultContent(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'text':
      return TextContent.fromJson(json);
    case 'image':
      return ClaudeImageContent.fromJson(json);
    case 'tool_use':
      return ToolUse.fromJson(json);
    default:
      throw Exception('Unrecognized content type');
  }
}
