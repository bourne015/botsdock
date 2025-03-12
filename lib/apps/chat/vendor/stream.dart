import 'dart:async';
import 'dart:convert';

import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fetch_client/fetch_client.dart';

import 'package:openai_dart/openai_dart.dart' as openai;

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
    debugPrint("error: ${e}");
  }
  return response;
}

class _PairwiseTransformer
    extends StreamTransformerBase<String, (String, String)> {
  @override
  Stream<(String, String)> bind(final Stream<String> stream) {
    late StreamController<(String, String)> controller;
    late StreamSubscription<String> subscription;
    // late String event;

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
              debugPrint("_PairwiseTransformer error: ${e}");
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
    extends StreamTransformerBase<List<int>, openai.AssistantStreamEvent> {
  const _OpenAIAssistantStreamTransformer();

  @override
  Stream<openai.AssistantStreamEvent> bind(final Stream<List<int>> stream) {
    return stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(_DataPreprocessorTransformer())
        .transform(_PairwiseTransformer())
        .map((final item) {
      final (event, data) = item;
      //print("event:${event}");
      // print("data:${data}");

      Map<String, dynamic> getEventDataMap({final bool decode = true}) => {
            'event': event,
            'data': decode ? json.decode(data) : data,
          };

      switch (event) {
        case 'thread.created':
          return openai.ThreadStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.created':
        case 'thread.run.queued':
        case 'thread.run.in_progress':
        case 'thread.run.requires_action':
        case 'thread.run.completed':
        case 'thread.run.failed':
        case 'thread.run.cancelling':
        case 'thread.run.cancelled':
        case 'thread.run.expired':
          return openai.RunStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.step.created':
        case 'thread.run.step.in_progress':
        case 'thread.run.step.completed':
        case 'thread.run.step.failed':
        case 'thread.run.step.cancelled':
        case 'thread.run.step.expired':
          return openai.RunStepStreamEvent.fromJson(getEventDataMap());
        case 'thread.run.step.delta':
          return openai.RunStepStreamDeltaEvent.fromJson(getEventDataMap());
        case 'thread.message.created':
        case 'thread.message.in_progress':
        case 'thread.message.completed':
        case 'thread.message.incomplete':
          return openai.MessageStreamEvent.fromJson(getEventDataMap());
        case 'thread.message.delta':
          return openai.MessageStreamDeltaEvent.fromJson(getEventDataMap());
        case 'error':
          return openai.ErrorEvent.fromJson(getEventDataMap());
        case 'done':
          return openai.DoneEvent.fromJson(getEventDataMap(decode: false));
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

Stream<openai.AssistantStreamEvent> CreateAssistantChatStream(
  String url, {
  String? method = "POST",
  Map<String, String>? headers = const {
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream'
  },
  String? body,
}) async* {
  var request = http.Request(method ?? "POST", Uri.parse(url));
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

// class _OpenAIStreamTransformer
//     extends StreamTransformerBase<List<int>, String> {
//   const _OpenAIStreamTransformer();

//   @override
//   Stream<String> bind(final Stream<List<int>> stream) {
//     return stream //
//         .transform(utf8.decoder) //
//         .transform(const LineSplitter()) //
//         .where((final i) => i.startsWith('data: ') && !i.endsWith('[DONE]'))
//         .map((final item) => item.substring(6));
//   }
// }

Future<Stream<String>> CreateChatStreamWithRetry(
  String url, {
  String method = "POST",
  Map<String, String> headers = const {
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream'
  },
  String? body,
  int retryCount = 3,
  Duration retryDelay = const Duration(seconds: 2),
  //Duration timeout = const Duration(seconds: 10),
}) async {
  for (int i = 0; i < retryCount; i++) {
    try {
      final responseStream = await CreateChatStream(url,
          method: method, headers: headers, body: body);
      //.timeout(timeout);
      return responseStream;
    } catch (error) {
      Logger.warn("CreateChatStreamWithRetry error: $error");
      await Future.delayed(retryDelay); // delay and retry
      if (i == retryCount - 1) rethrow;
    }
  }
  throw Exception('Failed to create chat stream after $retryCount attempts');
}

Stream<String> CreateChatStream(
  String url, {
  String? method = "POST",
  Map<String, String>? headers = const {
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream'
  },
  String? body,
}) async* {
  var request = http.Request(method ?? "POST", Uri.parse(url));
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
  var _newLine = false;

  try {
    stream.transform(const LineSplitter()).listen((String line) {
      if (line.length == 0) {
        _newLine = false;
      } else if (line.startsWith('data:')) {
        var data = line.substring(6);
        data = _newLine ? '\n' + data : data;
        controller.add(data);
        _newLine = true;
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
  } catch (e, s) {
    Logger.error("CreateChatStream catch error: $e, stack: $s");
    controller.addError(e);
    controller.close();
    rethrow;
  }
}
