//import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';

import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fetch_client/fetch_client.dart';

import '../models/chat.dart';
import '../models/pages.dart';
import '../models/message.dart';
import '../models/data.dart';
import '../models/schema/schema.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/global.dart';

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

Future<http.StreamedResponse> makeRequestStream(
  String url,
  String method,
  Map<String, String>? headers,
  String? body,
) async {
  var response;
  var request = http.Request(method, Uri.parse(url));
  if (headers != null) request.headers.addAll(headers);
  if (body != null) request.body = body;
  try {
    var client;
    if (kIsWeb)
      client = FetchClient(mode: RequestMode.cors);
    else
      client = http.Client();
    response = await client.send(request);
  } catch (e) {
    print("error: ${e}");
  }
  return response;
}

class _PairwiseTransformer
    extends StreamTransformerBase<String, (String, String)> {
  @override
  Stream<(String, String)> bind(final Stream<String> stream) {
    late StreamController<(String, String)> controller;
    late StreamSubscription<String> subscription;
    late String event;

    controller = StreamController<(String, String)>(
      onListen: () {
        subscription = stream.listen(
          (final String data) {
            try {
              if (data.isNotEmpty) {
                final parsedData = json.decode(data);
                final event = parsedData['event'] as String;
                final dataStr = json.encode(parsedData['data']);
                controller.add((event, dataStr));
              }
            } catch (e) {
              print("_PairwiseTransformer error: ${e}");
            }
          },
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: true,
        );
      },
      onPause: ([final resumeSignal]) => subscription.pause(resumeSignal),
      onResume: () => subscription.resume(),
      onCancel: () async => subscription.cancel(),
    );

    return controller.stream;
  }
}

class _OpenAIAssistantStreamTransformer
    extends StreamTransformerBase<List<int>, AssistantStreamEvent> {
  const _OpenAIAssistantStreamTransformer();

  @override
  Stream<AssistantStreamEvent> bind(final Stream<List<int>> stream) {
    return stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(_DataPreprocessorTransformer())
        .transform(_PairwiseTransformer())
        .map((final item) {
      final (event, data) = item;
      //print("event:${event}");

      Map<String, dynamic> getEventDataMap({final bool decode = true}) => {
            'event': event,
            'data': decode ? json.decode(data) : data,
          };

      switch (event) {
        case 'thread.created':
          return ThreadStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.created':
        case 'thread.run.queued':
        case 'thread.run.in_progress':
        case 'thread.run.requires_action':
        case 'thread.run.completed':
        case 'thread.run.failed':
        case 'thread.run.cancelling':
        case 'thread.run.cancelled':
        case 'thread.run.expired':
          return RunStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.step.created':
        case 'thread.run.step.in_progress':
        case 'thread.run.step.completed':
        case 'thread.run.step.failed':
        case 'thread.run.step.cancelled':
        case 'thread.run.step.expired':
          return RunStepStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.step.delta':
          return RunStepStreamDeltaEvent.fromJson(getEventDataMap());
        case 'thread.message.created':
        case 'thread.message.in_progress':
        case 'thread.message.completed':
        case 'thread.message.incomplete':
          return MessageStreamEvent.fromJson(getEventDataMap());
        case 'thread.message.delta':
          return MessageStreamDeltaEvent.fromJson(getEventDataMap());
        case 'error':
          return ErrorEvent.fromJson(getEventDataMap());
        case 'done':
          return DoneEvent.fromJson(getEventDataMap(decode: false));
        default:
          throw Exception('Unknown event: $event');
      }
    });
  }
}

class _DataPreprocessorTransformer
    extends StreamTransformerBase<String, String> {
  @override
  Stream<String> bind(final Stream<String> stream) {
    return stream.map((String data) {
      if (data.isNotEmpty) {
        var newData = 'data: ';
        newData = data.substring(5).replaceFirst(' ', '');
        data = data.length > 0 ? data : '\n';
        return newData;
      }
      return data;
    });
  }
}

Stream<AssistantStreamEvent> connectAssistant(
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
  var stream = response.stream;
  yield* stream.transform(const _OpenAIAssistantStreamTransformer());
}

class ChatSSE {
  Stream<String> connect(
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

class ChatGen {
  final dio = Dio();
  final ChatSSE chatServer = ChatSSE();
  Future<void> titleGenerate(Pages pages, int handlePageID) async {
    String q;
    try {
      if (pages.getPage(handlePageID).modelVersion == GPTModel.gptv40Dall) {
        q = pages.getMessages(handlePageID)!.first.content;
      } else if (pages.getMessages(handlePageID)!.length > 1) {
        q = pages.getMessages(handlePageID)![1].content;
      } else {
        //in case no input
        return;
      }
      // to save token
      q = q.length > 1000 ? q.substring(0, 1000) : q;
      var chatData1 = {
        "model": ClaudeModel.haiku,
        "question": "为这段话写一个5个字左右的标题:$q"
      };
      final response = await dio.post(chatUrl, data: chatData1);
      var title = response.data;
      // in case title too long
      title = title.length > 20 ? title.substring(0, 20) : title;
      pages.setPageTitle(handlePageID, title);
    } catch (e) {
      debugPrint("titleGenerate error: $e");
    }
  }

  //save chats to DB and local cache
  void saveChats(user, pages, handlePageID) async {
    if (user.id != 0) {
      //only store after user login
      var chatdbUrl = userUrl + "/" + "${user.id}" + "/chat";
      var chatData = {
        "id": pages.getPage(handlePageID).dbID,
        "page_id": handlePageID,
        "title": pages.getPage(handlePageID).title,
        "contents": pages.getPage(handlePageID).dbScheme,
        "model": pages.getPage(handlePageID).modelVersion,
        "assistant_id": pages.getPage(handlePageID).assistantID,
        "thread_id": pages.getPage(handlePageID).threadID,
        "bot_id": pages.getPage(handlePageID).botID,
      };

      Response cres = await dio.post(
        chatdbUrl,
        data: chatData,
      );
      if (cres.data["result"] == "success") {
        pages.getPage(handlePageID).dbID = cres.data["id"];
        pages.getPage(handlePageID).updated_at = cres.data["updated_at"];

        chatData["id"] = cres.data["id"];
        chatData["updated_at"] = cres.data["updated_at"];
        Global.saveChats(user, chatData["page_id"], jsonEncode(chatData),
            cres.data["updated_at"]);
      }
    }
  }

  void updateCredit(User user) async {
    var url = userUrl + "/${user.id}" + "/info";
    var response = await dio.post(url);
    if (response.data["result"] == "success")
      user.credit = response.data["credit"];
  }

  Future<String?> uploadImage(
      pages, pid, msg_id, oss_name, filename, imgData) async {
    String? ossUrl;
    try {
      var resp = await Client().putObject(imgData, "chat/image/" + oss_name);
      ossUrl = (resp.statusCode == 200) ? resp.realUri.toString() : null;
      //if (ossUrl != null) pages.updateFileUrl(pid, msg_id, filename, ossUrl);
    } catch (e) {
      debugPrint("uploadImage to oss error: $e");
    }
    return ossUrl;
  }

  void submitAssistant(Pages pages, Property property, int handlePageID, user,
      attachments) async {
    var assistant_id = pages.getPage(handlePageID).assistantID;
    var thread_id = pages.getPage(handlePageID).threadID;
    var _url =
        "${baseurl}/v1/assistant/vs/${assistant_id}/threads/${thread_id}/messages";
    try {
      var chatData = {
        "role": "user",
        "content": pages.getPage(handlePageID).chatScheme.last["content"],
        "attachments":
            attachments.values.map((attachment) => attachment.toJson()).toList()
      };
      ////debugPrint("send question: ${chatData["question"]}");
      final stream = connectAssistant(
        _url,
        "POST",
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream'
        },
        body: jsonEncode(chatData),
      );
      pages.setGeneratingState(handlePageID, true);
      Message? msgA;
      stream.listen((event) {
        String? _text;
        Map<String, Attachment> attachments = {};
        Map<String, VisionFile> visionFiles = {};
        if (event is MessageStreamEvent &&
            event.event == EventType.threadMessageCreated) {
          msgA = Message(
              id: pages.getPage(handlePageID).messages.length,
              pageID: handlePageID,
              role: MessageTRole.assistant,
              type: MsgType.text,
              content: "",
              visionFiles: copyVision(visionFiles),
              attachments: copyAttachment(attachments),
              timestamp: DateTime.now().millisecondsSinceEpoch);
          pages.addMessage(handlePageID, msgA!);
        }
        event.when(
            threadStreamEvent: (final event, final data) {},
            runStreamEvent: (final event, final data) {},
            runStepStreamEvent: (final event, final data) {
              if (data.usage != null) {
                print("promptTokens: ${data.usage!.promptTokens}");
                print("completionTokens: ${data.usage!.completionTokens}");
                print("totalTokens: ${data.usage!.totalTokens}");
              }
            },
            runStepStreamDeltaEvent: (final event, final data) {
              data.delta.stepDetails!.whenOrNull(
                toolCalls: (type, toolCalls) {
                  print("$type, $toolCalls");
                },
              );
            },
            messageStreamEvent: (final event, final data) {},
            messageStreamDeltaEvent: (final event, final data) {
              //data.delta.content?.map((final _content) {
              //print("test5.1: ${_content}");
              if (data.delta.content != null)
                data.delta.content![0].whenOrNull(
                    imageFile: (index, type, imageFileObj) {
                  var _image_fild_id = imageFileObj!.fileId;
                  attachments["${_image_fild_id}"] =
                      Attachment(file_id: _image_fild_id);
                }, text: (index, type, textObj) {
                  _text = textObj!.value;
                  if (textObj.annotations != null &&
                      textObj.annotations!.isNotEmpty)
                    textObj.annotations!.forEach((annotation) {
                      annotation.whenOrNull(fileCitation: (index, type, text,
                          file_citation, start_index, end_index) {
                        var file_name = text!.split('/').last;
                        attachments[file_name] =
                            Attachment(file_id: file_citation!.fileId);
                      }, filePath: (index, type, text, file_path, start_index,
                          end_index) {
                        var file_name = text!.split('/').last;
                        attachments[file_name] =
                            Attachment(file_id: file_path!.fileId);
                      });
                    });
                });
              //});
            },
            errorEvent: (final event, final data) {},
            doneEvent: (final event, final data) {});

        pages.appendMessage(handlePageID,
            msg: _text,
            visionFiles: copyVision(visionFiles),
            attachments: copyAttachment(attachments));
        //pages.setGeneratingState(handlePageID, true);
      }, onError: (e) {
        debugPrint('SSE error: $e');
        pages.setGeneratingState(handlePageID, false);
      }, onDone: () async {
        pages.setGeneratingState(handlePageID, false);
        debugPrint('SSE complete');
        if (msgA != null) pages.getPage(handlePageID).updateScheme(msgA!.id);
        var pageTitle = pages.getPage(handlePageID).title;
        if (pageTitle.length >= 6 && pageTitle.startsWith("Chat 0")) {
          await titleGenerate(pages, handlePageID);
        }
        saveChats(user, pages, handlePageID);
        updateCredit(user);
      });
    } catch (e) {
      debugPrint("gen error: $e");
      pages.setGeneratingState(handlePageID, false);
    }
  }

  void submitText(
      Pages pages, Property property, int handlePageID, user) async {
    bool _isNewReply = true;

    try {
      if (property.initModelVersion == GPTModel.gptv40Dall) {
        String q = pages.getMessages(handlePageID)!.last.content;
        var chatData1 = {"model": GPTModel.gptv40Dall, "question": q};
        pages.getPage(handlePageID).onGenerating = true;
        final response = await dio.post(imageUrl, data: chatData1);
        pages.getPage(handlePageID).onGenerating = false;

        var mt = DateTime.now().millisecondsSinceEpoch;
        String _aiImageName = "ai${user.id}_${handlePageID}_${mt}.png";
        Message msgA = Message(
            id: pages.getPage(handlePageID).messages.length,
            pageID: handlePageID,
            role: MessageTRole.assistant,
            type: MsgType.image,
            //fileUrl: ossUrl,
            visionFiles: {
              _aiImageName: VisionFile(
                  name: "ai_file", bytes: base64Decode(response.data))
            },
            content: "",
            timestamp: mt);
        pages.addMessage(handlePageID, msgA);
        if (response.statusCode == 200 &&
            pages.getPage(handlePageID).title == "Chat 0") {
          await titleGenerate(pages, handlePageID);
        }

        await uploadImage(pages, handlePageID, msgA.id, _aiImageName,
            _aiImageName, base64Decode(response.data));
        saveChats(user, pages, handlePageID);
      } else {
        var chatData = {
          "model": pages.currentPage?.modelVersion,
          "question": pages.getPage(handlePageID).chatScheme,
        };
        ////debugPrint("send question: ${chatData["question"]}");
        final stream = chatServer.connect(
          sseChatUrl,
          "POST",
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream'
          },
          body: jsonEncode(chatData),
        );
        pages.getPage(handlePageID).onGenerating = true;
        stream.listen((data) {
          if (_isNewReply) {
            Message msgA = Message(
                id: pages.getPage(handlePageID).messages.length,
                pageID: handlePageID,
                role: MessageTRole.assistant,
                type: MsgType.text,
                content: data,
                timestamp: DateTime.now().millisecondsSinceEpoch);
            pages.addMessage(handlePageID, msgA);
          } else {
            pages.appendMessage(handlePageID, msg: data);
          }
          pages.getPage(handlePageID).onGenerating = true;
          _isNewReply = false;
        }, onError: (e) {
          debugPrint('SSE error: $e');
          pages.getPage(handlePageID).onGenerating = false;
        }, onDone: () async {
          debugPrint('SSE complete');
          pages.getPage(handlePageID).onGenerating = false;
          var pageTitle = pages.getPage(handlePageID).title;
          if (pageTitle.length >= 6 && pageTitle.substring(0, 6) == "Chat 0") {
            await titleGenerate(pages, handlePageID);
          }
          saveChats(user, pages, handlePageID);
          updateCredit(user);
        });
      }
    } catch (e) {
      debugPrint("gen error: $e");
      pages.getPage(handlePageID).onGenerating = false;
    }
  }

  void newBot(Pages pages, Property property, User user, name, prompt) {
    int handlePageID = pages.addPage(Chat(title: name), sort: true);
    property.onInitPage = false;
    pages.currentPageID = handlePageID;
    pages.setPageTitle(handlePageID, name);
    pages.currentPage?.modelVersion = property.initModelVersion;

    Message msgQ = Message(
        id: 0,
        pageID: handlePageID,
        role: MessageTRole.system,
        type: MsgType.text,
        content: prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    pages.addMessage(handlePageID, msgQ);
    submitText(pages, property, handlePageID, user);
  }

  void newTextChat(Pages pages, Property property, User user, String prompt) {
    int handlePageID = pages.addPage(Chat(title: "Chat 0"), sort: true);
    property.onInitPage = false;
    pages.currentPageID = handlePageID;
    pages.currentPage?.modelVersion = property.initModelVersion;

    Message msgQ = Message(
        id: 0,
        pageID: handlePageID,
        role: MessageTRole.user,
        type: MsgType.text,
        content: prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    pages.addMessage(handlePageID, msgQ);
    submitText(pages, property, handlePageID, user);
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
    copy[_filename] =
        Attachment(file_id: _content.file_id, tools: List.from(_content.tools));
  });
  return copy;
}
