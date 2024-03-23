import 'dart:convert';
import '../utils/constants.dart';

class Message {
  final String id;
  final int pageID;
  final String role;
  MsgType? type;
  String content;
  String? fileName;
  List<int>? fileBytes;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.pageID,
    required this.role,
    this.type = MsgType.text,
    required this.content,
    this.fileName,
    this.fileBytes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap(String modelVersion) {
    var res = <String, dynamic>{};
    if (type == MsgType.image && fileBytes != null) {
      // final html.File htmlFile = html.File(
      //   fileBytes!,
      //   file!.name,
      //   {'type': file!.mimeType},
      // );
      String fileType = fileName!.split('.').last.toLowerCase();
      String fileBase64 = base64Encode(fileBytes!);
      if (modelVersion.substring(0, 6) == "claude") {
        //claude model
        res = {
          'role': role,
          'content': [
            {'type': 'text', 'text': content},
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                "media_type": 'image/$fileType',
                'data': fileBase64,
              },
            },
          ]
        };
      } else {
        //gpt model
        res = {
          'role': role,
          'content': [
            {'type': 'text', 'text': content},
            {
              'type': 'image_url',
              'image_url': {
                'url': "data:$fileType;base64,$fileBase64",
              },
            },
          ]
        };
      }
    } else {
      res = {
        'role': role,
        'content': type == MsgType.file
            ? '<paper>$fileBytes</paper>' + content
            : content,
      };
    }
    return res;
  }
}
