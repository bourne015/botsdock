import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fetch_client/fetch_client.dart';

import '../models/bot.dart';
import '../models/chat.dart';
import '../models/pages.dart';
import '../models/user.dart';

class AssistantsAPI {
  final dio = Dio();

  /**
   * upload file to backend
   */
  Future<void> uploadFile(selectedFile) async {
    try {
      if (selectedFile == null) return;
      var file = selectedFile!.files.first;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://fantao.life:8001/v1/files'),
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
   * create openai vector store with files
   */
  Future<String> createVectorStore(selectedFile) async {
    var url = 'https://fantao.life:8001/v1/assistant/vs';
    try {
      var files = selectedFile.map((pfile) {
        return pfile.files.first.name;
      }).toList();
      var vs_data = {"vs_name": "", "files": files};
      final response = await dio.post(url, data: vs_data);
      if (response.statusCode == 200) return response.data["vs_id"];
    } catch (error) {
      debugPrint('createVectorStore error: $error');
    }
    return "";
  }

  /**
   * upload file to openai.
   */
  Future<String> fileUpload(fileName) async {
    var url = 'https://fantao.life:8001/v1/assistant/files';

    var vs_data = {
      'file_name': fileName,
    };
    try {
      final response = await dio.post(url, queryParameters: vs_data);
      if (response.statusCode == 200) return response.data["id"];
    } catch (error) {
      debugPrint('fileUpload error: $error');
    }
    return "";
  }

  /**
   * delete file in openai.
   */
  Future<bool> filedelete(fileID) async {
    var url = 'https://fantao.life:8001/v1/assistant/files/${fileID}';
    try {
      final response = await dio.delete(url);
      if (response.statusCode == 200) return true;
    } catch (error) {
      debugPrint('filedelete error: $error');
    }
    return false;
  }

  /**
     * Create a vector store file by attaching a it to a vector store.
     */
  Future<Map> vectorStoreFile(vid, fileName) async {
    var url = 'https://fantao.life:8001/v1/assistant/vs/${vid}/files';
    var vs_data = {
      //'vector_store_id': vid,
      'file_name': fileName,
    };
    try {
      final response = await dio.post(url, queryParameters: vs_data);
      if (response.statusCode == 200) return response.data;
    } catch (error) {
      debugPrint('vectorStoreFile error: $error');
    }
    return {};
  }

/**
 * delete file in vector store
 */
  Future<bool> vectorStoreFileDelete(vid, fileID) async {
    var url = 'https://fantao.life:8001/v1/assistant/vs/${vid}/files/${fileID}';

    try {
      final response = await dio.delete(url);
      if (response.statusCode == 200) return true;
    } catch (error) {
      debugPrint('vectorStoreFileDelete error: $error');
    }
    return false;
  }

/**
 * delete vector store
 */
  Future<bool> vectorStoreDelete(vid) async {
    var url = 'https://fantao.life:8001/v1/assistant/vs/${vid}';

    try {
      final response = await dio.delete(url);
      if (response.statusCode == 200) return true;
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
      var url = 'https://fantao.life:8001/v1/assistant/vs/${vid}/files';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        print("get files: ${response.data["files"]}");
        //setState(() {
        // vectoreStoreFiles = response.data["files"];
        //});
        return response.data["files"];
      } else {
        print("error: ${response.data["result"]}");
      }
    } catch (error) {
      print("error: $error");
    }
    return [];
  }

  /**
   *  create a thread
   */
  Future<String?> createThread() async {
    var url = 'https://fantao.life:8001/v1/assistant/threads';
    try {
      final response = await dio.post(url);
      if (response.statusCode == 200) return response.data["id"];
    } catch (error) {
      debugPrint('createThread error: $error');
    }
    return null;
  }

  /**
   *  delete a thread
   */
  Future<bool> deleteThread(String thread_id) async {
    var url = 'https://fantao.life:8001/v1/assistant/threads/${thread_id}';
    try {
      final response = await dio.delete(url);
      if (response.statusCode == 200) return true;
    } catch (error) {
      debugPrint('deleteThread error: $error');
    }
    return false;
  }

  /**
   * newassistant()
   */
  void newassistant(
      Pages pages, Property property, User user, Bot bot, String thread_id) {
    int handlePageID = pages.addPage(Chat(title: bot.name), sort: true);
    property.onInitPage = false;
    pages.currentPageID = handlePageID;
    pages.setPageTitle(handlePageID, bot.name);
    pages.getPage(handlePageID).modelVersion = property.initModelVersion;
    pages.getPage(handlePageID).assistantID = bot.assistant_id;
    pages.getPage(handlePageID).threadID = thread_id;
    pages.getPage(handlePageID).botID = bot.id;
    print("test bot: $bot, thread:$thread_id");
  }

  Stream<String> SSE(
    String url,
    String method, {
    Map<String, String>? headers,
    String? body,
  }) async* {
    var request = http.Request(method, Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;

    var client;
    if (kIsWeb)
      client = FetchClient(mode: RequestMode.cors);
    else
      client = http.Client();
    var response = await client.send(request);
    var stream = response.stream.transform<String>(utf8.decoder);
    final controller = StreamController<String>();

    try {
      stream.transform(const LineSplitter()).listen((String line) {
        if (line.isNotEmpty) {
          var data = line.substring(5).replaceFirst(' ', '');
          data = data.length > 0 ? data : '\n';
          controller.add(data);
        }
      }, onDone: () {
        controller.close();
        client.close();
      }, onError: (error) {
        controller.addError(error);
        controller.close();
        client.close();
      });
      yield* controller.stream;
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
  }
}
