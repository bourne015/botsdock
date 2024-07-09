import 'dart:convert';
import '../utils/constants.dart';

class Message {
  final int id;
  final int? pageID;
  final String role;
  MsgType type;
  String content;
  String? fileName;
  List<int>? fileBytes;
  String? fileUrl;
  Map? attachments;
  final int? timestamp;

  Message({
    required this.id,
    required this.pageID,
    required this.role,
    this.type = MsgType.text,
    required this.content,
    this.fileName,
    this.fileBytes,
    this.fileUrl,
    this.attachments,
    required this.timestamp,
  });

  List claudeImgMsg() {
    List claudeContent = [
      {'type': 'text', 'text': content},
      {}
    ];

    if (fileBytes != null) {
      String fileType = fileName!.split('.').last.toLowerCase();
      String fileBase64 = base64Encode(fileBytes!);
      var claude_img = {
        'type': 'image',
        'source': {
          'type': 'base64',
          "media_type": 'image/$fileType',
          'data': fileBase64,
        },
      };
      claudeContent = [
        {'type': 'text', 'text': content},
        ...[claude_img]
      ];
    }
    return claudeContent;
  }

  List gptImgMsg() {
    List gptContent = [];
    String? _imgData;

    if (fileUrl == null && fileBytes != null) {
      String fileType = fileName!.split('.').last.toLowerCase();
      String fileBase64 = base64Encode(fileBytes!);
      _imgData = "data:image/ang$fileType;base64,$fileBase64";
    } else
      _imgData = fileUrl;
    gptContent = [
      {'type': 'text', 'text': content},
      {
        'type': 'image_url',
        'image_url': {'url': _imgData},
      },
    ];
    return gptContent;
  }

  //text message
  //file is treated as text
  String textMsg() {
    if (type == MsgType.file)
      return '<paper>$fileBytes</paper>' + content;
    else
      return content;
  }

  //text case, content is a string
  //vision case, image data stores in content, content is a list
  //generate image case, image data stores in fileBytes, content is empty
  //
  Map<String, dynamic> toMap(String modelVersion) {
    var input_msg = <String, dynamic>{'role': role};
    Map? msgStore = {
      "id": id,
      "pageID": pageID,
      "role": role,
      "type": type.index,
      "fileName": fileName,
      "fileBytes": null,
      "fileUrl": fileUrl,
      "attachments": attachments,
      "content": content,
      "timestamp": timestamp
    };
    if (type == MsgType.image && role == MessageRole.user) {
      if (modelVersion.substring(0, 6) == "claude") {
        input_msg["content"] = claudeImgMsg();
      } else {
        input_msg["content"] = gptImgMsg();
        // if (fileUrl != null)
        //   msgStore["content"] = jsonEncode(input_msg["content"]);
      }
    } else {
      input_msg["content"] = textMsg();
    }
    return {"db_scheme": msgStore, "chat_scheme": input_msg};
  }
}
