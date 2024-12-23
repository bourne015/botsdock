import '../../models/data.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:openai_dart/openai_dart.dart' as openai;

export "openai.dart";
export "claude.dart";

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

abstract class Message {
  int id;
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
    required this.id,
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
