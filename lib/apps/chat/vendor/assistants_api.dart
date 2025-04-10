import 'dart:async';

import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';

import '../models/bot.dart';
import '../models/chat.dart';
import '../models/pages.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AssistantsAPI {
  final dio = DioClient();

  /**
   * upload file to backend
   */
  Future<void> uploadFile(selectedFile) async {
    try {
      if (selectedFile == null) return;
      var file = selectedFile!.files.first;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${BASE_URL}/v1/files'),
      );
      // request.files.add(
      //     await http.MultipartFile.fromPath('file', selectedFile!.files.first));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));
      var response = await request.send();
      if (response.statusCode == 200) debugPrint('File uploaded successfully');
    } catch (error) {
      debugPrint('uploadFile to backend error: $error');
    }
  }

/**
   * download file from backend
   */
  Future<String> downloadFile(String file_id, String? file_name) async {
    var _data;
    try {
      var url = "${BASE_URL}/v1/assistant/files/${file_id}";
      var _param = {"file_name": file_name};
      _data = await dio.get(
        url,
        queryParameters: _param,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final Uint8List bytes = Uint8List.fromList(_data);
      await FileSaver.instance
          .saveFile(name: file_name ?? file_id, bytes: bytes);
      return "success";
    } catch (error) {
      debugPrint('downloadFile from backend error: $error');
    }
    return "failed";
  }

  /**
   * create openai vector store with files
   */
  Future<String> createVectorStore(selectedFile) async {
    var url = '${BASE_URL}/v1/assistant/vs';
    try {
      var files = selectedFile.map((pfile) {
        return pfile.files.first.name;
      }).toList();
      var vs_data = {"vs_name": "", "files": files};
      final _data = await dio.post(url, data: vs_data);
      return _data["vs_id"];
    } catch (error) {
      debugPrint('createVectorStore error: $error');
    }
    return "";
  }

  /**
   * upload file to openai.
   */
  Future<String> fileUpload(fileName) async {
    var url = '${BASE_URL}/v1/assistant/files';

    var vs_data = {
      'file_name': fileName,
    };
    try {
      final _data = await dio.post(url, queryParameters: vs_data);
      return _data["id"];
    } catch (error) {
      debugPrint('fileUpload error: $error');
    }
    return "";
  }

  /**
   * delete file in openai.
   */
  Future<bool> filedelete(fileID) async {
    var url = '${BASE_URL}/v1/assistant/files/${fileID}';
    try {
      await dio.delete(url);
      return true;
    } catch (error) {
      debugPrint('filedelete error: $error');
    }
    return false;
  }

  /**
     * Create a vector store file by attaching a it to a vector store.
     */
  Future<Map> vectorStoreFile(vid, fileName) async {
    var url = '${BASE_URL}/v1/assistant/vs/${vid}/files';
    var vs_data = {
      //'vector_store_id': vid,
      'file_name': fileName,
    };
    try {
      final _data = await dio.post(url, queryParameters: vs_data);
      return _data;
    } catch (error) {
      debugPrint('vectorStoreFile error: $error');
    }
    return {};
  }

/**
 * delete file in vector store
 */
  Future<bool> vectorStoreFileDelete(vid, fileID) async {
    var url = '${BASE_URL}/v1/assistant/vs/${vid}/files/${fileID}';

    try {
      await dio.delete(url);
      return true;
    } catch (error) {
      debugPrint('vectorStoreFileDelete error: $error');
    }
    return false;
  }

/**
 * delete vector store
 */
  Future<bool> vectorStoreDelete(vid) async {
    var url = '${BASE_URL}/v1/assistant/vs/${vid}';

    try {
      await dio.delete(url);
      return true;
    } catch (error) {
      debugPrint('vectorStoreDelete error: $error');
    }
    return false;
  }

  /**
   * get all file of vector store
   */
  Future<List> getVectorStoreFiles(vectorStoreId) async {
    try {
      var vid = vectorStoreId.keys.first;
      var url = '${BASE_URL}/v1/assistant/vs/${vid}/files';
      final _data = await dio.get(url);

      print("get files: ${_data["files"]}");
      //setState(() {
      // vectoreStoreFiles = response.data["files"];
      //});
      return _data["files"];
    } catch (error) {
      print("error: $error");
    }
    return [];
  }

  /**
   *  create a thread
   */
  Future<String?> createThread() async {
    var url = '${BASE_URL}/v1/assistant/threads';
    try {
      final _data = await dio.post(url);
      return _data["id"];
    } catch (error) {
      debugPrint('createThread error: $error');
    }
    return null;
  }

  Future<bool> retriveThread(String thread_id) async {
    var url = '${BASE_URL}/v1/assistant/threads/${thread_id}';
    try {
      await dio.post(url);
      return true;
    } catch (e) {
      debugPrint('retriveThread error: $e');
    }
    return false;
  }

  /**
   *  delete a thread
   */
  Future<bool> deleteThread(String thread_id) async {
    var url = '${BASE_URL}/v1/assistant/threads/${thread_id}';
    try {
      await dio.delete(url);
      return true;
    } catch (error) {
      debugPrint('deleteThread error: $error');
    }
    return false;
  }

  /**
   * newassistant()
   */
  int newassistant(Pages pages, Property property, User user, String thread_id,
      {Bot? bot, String? ass_id, String? chat_title, String? model}) {
    String? _model = model != null
        ? model
        : (bot != null && bot.model != null)
            ? bot.model
            : property.initModelVersion;
    int handlePageID = pages.addPage(
        Chat(
            title: (bot != null ? bot.name : chat_title ?? "Chat 0"),
            model: _model!),
        sort: true);
    property.onInitPage = false;
    pages.currentPageID = handlePageID;
    //pages.setPageTitle(handlePageID, bot.name);
    pages.getPage(handlePageID).model = _model;
    pages.getPage(handlePageID).assistantID =
        (bot != null ? bot.assistant_id : ass_id);
    pages.getPage(handlePageID).threadID = thread_id;
    pages.getPage(handlePageID).botID = (bot != null ? bot.id : null);
    debugPrint("test bot: $bot, thread:$thread_id");
    return handlePageID;
  }
}
