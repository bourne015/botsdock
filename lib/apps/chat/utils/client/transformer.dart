import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:openai_dart/openai_dart.dart' as openai;

class OpenAIStreamTransformer extends StreamTransformerBase<List<int>, String> {
  const OpenAIStreamTransformer();

  @override
  Stream<String> bind(final Stream<List<int>> stream) {
    return stream //
        .transform(utf8.decoder) //
        .transform(const LineSplitter()) //
        .where((final i) => i.startsWith('data: ') && !i.endsWith('[DONE]'))
        .map((final item) => item.substring(6));
  }
}

class OpenAIAssistantStreamTransformer
    extends StreamTransformerBase<List<int>, openai.AssistantStreamEvent> {
  const OpenAIAssistantStreamTransformer();

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
