import 'dart:convert';

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dart:async';

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
