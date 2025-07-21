import 'dart:io';
import 'dart:typed_data';

import 'package:botsdock/apps/chat/models/mcp/mcp_server_config.dart';
import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:mcp_dart/mcp_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void downloadImageFile(
    {String? fileName, String? fileUrl, Uint8List? imageData}) async {
  final String name =
      fileName ?? 'ai_image_${DateTime.now().millisecondsSinceEpoch}.png';
  try {
    // 获取图片数据
    Uint8List? imgData = imageData;
    if (imgData == null && fileUrl != null) {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        imgData = response.bodyBytes;
      } else {
        Logger.info(
            "Failed to download image from URL: ${response.statusCode}");
        return;
      }
    }

    if (imgData == null) {
      Logger.info("No image data to download");
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      await _saveToGallery(imgData, name);
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await _saveToDesktop(imgData, name);
    }
  } catch (e) {
    Logger.info("Error downloading image: $e");
  }
}

Future<void> _saveToGallery(Uint8List imageData, String name) async {
  // 检查权限
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      Logger.info("Storage permission denied");
      return;
    }
  }

  final result = await FlutterImageGallerySaver.saveImage(
    imageData,
    // name: name,
    // quality: 100,
  );

  // if (result['isSuccess']) {
  //   Logger.info("Image saved to gallery");
  // } else {
  //   Logger.info("Failed to save image to gallery: ${result['error']}");
  // }
}

Future<void> _saveToDesktop(Uint8List imageData, String name) async {
  try {
    // Directory? downloadsDir = await getDownloadsDirectory();
    Directory? downloadsDir = await getApplicationDocumentsDirectory();
    if (downloadsDir == null) {
      // Logger.info("Could not access downloads directory");

      // final tempDir = await getTemporaryDirectory();
      // final file = File('${tempDir.path}/$name');
      // await file.writeAsBytes(imageData);
      // await Share.shareXFiles([XFile(file.path)],
      //     text: 'Image shared from app');
      // return;
      downloadsDir = await getTemporaryDirectory();
    }
    Logger.warn("test path: ${downloadsDir.path}");

    final String path = '${downloadsDir.path}/$name';
    final File file = File(path);
    await file.writeAsBytes(imageData);
    Logger.info("Image saved to $path");
  } catch (e) {
    Logger.info("Error saving to desktop: $e");
  }
}

Map<String, String> parseUrlParams() {
  return {};
}

void clearUrlQueryParams() {
  return;
}

dynamic CreateClientTransport(
  TransportType transportType,
  String? command,
  List<String> args,
  Map<String, String> environment,
  String? sessionId,
) {
  if (transportType == TransportType.StreamableHTTP) {
    return StreamableHttpClientTransport(
      Uri.parse(args[0]),
      opts: StreamableHttpClientTransportOptions(
        sessionId: sessionId,
        reconnectionOptions: StreamableHttpReconnectionOptions(
          initialReconnectionDelay: 1000,
          maxReconnectionDelay: 30000,
          reconnectionDelayGrowFactor: 1.5,
          maxRetries: 3,
        ),
      ),
    );
  } else {
    return StdioClientTransport(
      StdioServerParameters(
        command: command!,
        args: args,
        environment: environment,
        stderrMode: ProcessStartMode.normal,
      ),
    );
  }
}
