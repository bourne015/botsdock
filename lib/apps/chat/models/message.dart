import 'dart:convert';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../models/data.dart';

class Message {
  final int id;
  final int? pageID;
  final String role;
  MsgType type;
  String content;
  Map<String, Attachment> attachments = {};
  Map<String, VisionFile> visionFiles = {};
  final int? timestamp;

  Message({
    required this.id,
    required this.pageID,
    required this.role,
    this.type = MsgType.text,
    required this.content,
    this.attachments = const {},
    this.visionFiles = const {},
    required this.timestamp,
  });

  List claudeImgMsg() {
    List claudeContent = [];

    if (visionFiles.isNotEmpty) {
      visionFiles.forEach((_filename, _content) {
        String fileType = _filename.split('.').last.toLowerCase();
        String fileBase64 = base64Encode(_content.bytes);
        var claude_img_title = {"type": "text", "text": "Image:"};
        var claude_img = {
          'type': 'image',
          'source': {
            'type': 'base64',
            "media_type": 'image/$fileType',
            'data': fileBase64,
          },
        };
        claudeContent.add(claude_img_title);
        claudeContent.add(claude_img);
      });
    }
    claudeContent.add({'type': 'text', 'text': content});
    return claudeContent;
  }

  List gptImgMsg() {
    List gptContent = [];

    if (visionFiles.isNotEmpty) {
      visionFiles.forEach((_filename, _content) {
        var _imgData = "";
        if (_content.url.isNotEmpty)
          _imgData = _content.url;
        else if (_content.bytes.isNotEmpty) {
          String fileType = _filename.split('.').last.toLowerCase();
          String fileBase64 = base64Encode(_content.bytes);
          _imgData = "data:image/$fileType;base64,$fileBase64";
        }
        var _gpt_img = {
          'type': 'image_url',
          'image_url': {'url': _imgData},
        };
        gptContent.add(_gpt_img);
      });
      gptContent.add({'type': 'text', 'text': content});
    }
    return gptContent;
  }

  //text message
  //file is treated as text
  String textMsg() {
    // add fileBytes in content is a bad workaround
    // only support gpt assistant file workaround
    // if (type == MsgType.file)
    //   return '<paper>$fileBytes</paper>' + content;
    // else
    return content;
  }

  Map<String, dynamic> copyWithoutFileBytes(Map? original) {
    Map<String, dynamic> copy = {};
    if (original == null) return copy;
    copy =
        original.map((key, visionFile) => MapEntry(key, visionFile.toJson()));
    return copy;
  }

  //text case, content is a string
  //vision case, image data stores in content, content is a list
  //generate image case, image data stores in fileBytes, content is empty
  //
  Map<String, dynamic> toMap(String modelVersion) {
    var input_msg = <String, dynamic>{'role': role};
    Map msgStore = {};
    try {
      msgStore = {
        "id": id,
        "pageID": pageID,
        "role": role,
        "type": type.index,
        "visionFiles": copyWithoutFileBytes(visionFiles),
        "attachments": attachments
            .map((key, attachment) => MapEntry(key, attachment.toJson())),
        "content": content,
        "timestamp": timestamp
      };
      if (type == MsgType.image && role == MessageRole.user) {
        if (modelVersion.substring(0, 6) == "claude")
          input_msg["content"] = claudeImgMsg();
        else
          input_msg["content"] = gptImgMsg();
      } else {
        input_msg["content"] = textMsg();
      }
    } catch (error) {
      debugPrint("toMap error:${error}");
    }
    return {"db_scheme": msgStore, "chat_scheme": input_msg};
  }
}
