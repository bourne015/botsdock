import 'dart:convert';
import 'dart:typed_data';

import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:highlight/languages/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../models/data.dart';

enum AdaptiveWindowType {
  small,
  medium,
  large,
}

AdaptiveWindowType getAdaptiveWindowType(BuildContext context) {
  final double width = MediaQuery.of(context).size.width;

  if (width < 600) {
    return AdaptiveWindowType.small;
  } else if (width < 1200) {
    return AdaptiveWindowType.medium;
  } else {
    return AdaptiveWindowType.large;
  }
}

bool isDisplayDesktop(BuildContext context) {
  final windowType = getAdaptiveWindowType(context);
  return windowType == AdaptiveWindowType.large;
}

bool isDisplayFoldable(BuildContext context) {
  final hinge = MediaQuery.of(context).hinge;
  if (hinge == null) {
    return false;
  } else {
    // 判断是否为垂直铰链
    return hinge.bounds.size.aspectRatio < 1;
  }
}

Map<String, VisionFile> copyVision(Map? original) {
  Map<String, VisionFile> copy = {};
  if (original == null) return copy;
  original.forEach((_filename, _content) {
    copy[_filename] =
        VisionFile(name: _filename, bytes: _content.bytes, url: _content.url);
  });
  return copy;
}

Map<String, Attachment> copyAttachment(Map? original) {
  Map<String, Attachment> copy = {};
  if (original == null) return copy;
  original.forEach((_filename, _content) {
    copy[_filename] = Attachment(
      file_name: _content.file_name,
      file_id: _content.file_id,
      file_url: _content.file_url,
      downloading: _content.downloading,
      tools: List.from(_content.tools),
    );
  });
  return copy;
}

bool isValidJson(String jsonString) {
  try {
    json.decode(jsonString);
    return true;
  } on FormatException catch (_) {
    return false;
  }
}

Future<String> getVersionNumber() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

void downloadImage({String? fileName, String? fileUrl, Uint8List? imageData}) {
  String url;
  if (fileUrl != null) {
    url = fileUrl;
    debugPrint("download from url: $url");
  } else if (imageData != null) {
    final blob = web.Blob([imageData.toJS].toJS);
    url = web.URL.createObjectURL(blob as JSObject);
    debugPrint("download from asset");
  } else {
    debugPrint("empty image to download");
    return;
  }
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', fileName ?? 'ai')
    ..click();
  if (imageData != null) web.URL.revokeObjectURL(url);
}

Future<List> google_search(
    {required String query, int num_results = 10}) async {
  final request = http.Request(
    'GET',
    Uri.parse(
        '${BASE_URL}/v1/google_search/?query=$query&num_results=$num_results'),
  );

  // You can modify headers or other properties if needed
  request.headers.addAll({
    'Accept': 'application/json',
    // Add any other necessary headers here
  });

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data;
  }
  debugPrint('请求失败，状态码: ${response.statusCode}');
  return [];
}

Future<String> webpage_query({required String url}) async {
  final request = http.Request(
    'GET',
    Uri.parse('${BASE_URL}/v1/google_search/?url=$url'),
  );

  // You can modify headers or other properties if needed
  request.headers.addAll({
    'Accept': 'application/json',
    // Add any other necessary headers here
  });

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data;
  }
  debugPrint('请求失败，状态码: ${response.statusCode}');
  return "empty";
}
