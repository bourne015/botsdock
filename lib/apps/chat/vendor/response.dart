import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/material.dart';

import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:googleai_dart/googleai_dart.dart' as gemini;

class AIResponse {
  static void Openai(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    var res = openai.CreateChatCompletionStreamResponse.fromJson(j);
    pages.getPage(handlePageID).appendMessage(
          msg: res.choices[0].delta.content,
          toolCalls: res.choices[0].delta.toolCalls,
        );

    if (res.choices[0].finishReason ==
        openai.ChatCompletionFinishReason.toolCalls) {
      pages.getPage(handlePageID).setOpenaiToolInput();
      ChatAPI().submitText(pages, property, handlePageID, user);
    }
  }

  static void openaiAssistant(
    Pages pages,
    int handlePageID,
    openai.AssistantStreamEvent event,
  ) {
    String? _text;
    Map<String, Attachment> attachments = {};
    Map<String, VisionFile> visionFiles = {};
    if (event.event == openai.EventType.threadMessageCreated) {}

    pages.getPage(handlePageID).messages.last.onThinking = false;
    // print("_handleAssistantStream: ${event}");
    event.when(
        threadStreamEvent: (final event, final data) {},
        runStreamEvent: (final event, final data) {
          if (data.lastError != null) {
            debugPrint("lastError: ${data.lastError?.message}");
            _text = data.lastError?.message;
          }
        },
        runStepStreamEvent: (final event, final data) {
          if (data.usage != null) {
            debugPrint("promptTokens: ${data.usage!.promptTokens}");
            debugPrint("completionTokens: ${data.usage!.completionTokens}");
            debugPrint("totalTokens: ${data.usage!.totalTokens}");
          }
        },
        runStepStreamDeltaEvent: (final event, final data) {
          data.delta.stepDetails!.whenOrNull(
            toolCalls: (type, toolCalls) {
              debugPrint("$type, $toolCalls");
            },
          );
        },
        messageStreamEvent: (final event, final data) {},
        messageStreamDeltaEvent: (final event, final data) {
          if (data.delta.content != null)
            data.delta.content![0].whenOrNull(
              imageFile: (index, type, imageFileObj) {
                var _image_fild_id = imageFileObj!.fileId;
                attachments["${_image_fild_id}"] =
                    Attachment(file_id: _image_fild_id);
              },
              text: (index, type, textObj) {
                _text = textObj!.value;
                if (textObj.annotations != null &&
                    textObj.annotations!.isNotEmpty)
                  textObj.annotations!.forEach((annotation) {
                    annotation.whenOrNull(
                      fileCitation: (index, type, text, file_citation,
                          start_index, end_index) {
                        var file_name = text!.split('/').last;
                        attachments[file_name] =
                            Attachment(file_id: file_citation!.fileId);
                      },
                      filePath: (index, type, text, file_path, start_index,
                          end_index) {
                        var file_name = text!.split('/').last;
                        attachments[file_name] =
                            Attachment(file_id: file_path!.fileId);
                      },
                    );
                  });
              },
            );
          //});
        },
        errorEvent: (final event, final data) {
          debugPrint("errorEvent: $data");
        },
        doneEvent: (final event, final data) {
          debugPrint("doneEvent");
        });

    pages.getPage(handlePageID).appendMessage(
        msg: _text,
        visionFiles: copyVision(visionFiles),
        attachments: copyAttachment(attachments));
    //pages.setGeneratingState(handlePageID, true);
  }

  static void Claude(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    try {
      anthropic.MessageStreamEvent res =
          anthropic.MessageStreamEvent.fromJson(j);
      res.whenOrNull(
        contentBlockStart:
            (anthropic.Block b, int i, anthropic.MessageStreamEventType t) {
          pages.getPage(handlePageID).addTool(
                  toolUse: b.mapOrNull(
                toolUse: (x) => anthropic.ToolUseBlock(
                  id: x.id,
                  name: x.name,
                  input: x.input,
                ),
              ));
        },
        contentBlockDelta: (anthropic.BlockDelta b, int i,
            anthropic.MessageStreamEventType t) {
          pages.getPage(handlePageID).appendMessage(
                index: i,
                msg: b.mapOrNull(textDelta: (x) => x.text),
                toolUse: b.mapOrNull(inputJsonDelta: (x) => x.partialJson),
              );
        },
        contentBlockStop: (int i, anthropic.MessageStreamEventType t) {
          if (pages.getPage(handlePageID).messages.last.content is List &&
              pages.getPage(handlePageID).messages.last.content[i].type ==
                  "tool_use") {
            pages.getPage(handlePageID).setClaudeToolInput(i);
            var _toolID =
                pages.getPage(handlePageID).messages.last.content[i].id;
            pages.getPage(handlePageID).addMessage(role: MessageTRole.user);
            pages.getPage(handlePageID).addTool(
                  toolResult: anthropic.ToolResultBlock(
                    toolUseId: _toolID,
                    isError: false,
                    content:
                        anthropic.ToolResultBlockContent.text("tool result"),
                  ),
                );
            ChatAPI().submitText(pages, property, handlePageID, user);
          }
        },
      );
    } catch (e) {
      pages.getPage(handlePageID).appendMessage(
            msg: j.toString() + e.toString(),
          );
    }
  }

  static void DeepSeek(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    var res = openai.CreateChatCompletionStreamResponse.fromJson(j);
    pages.getPage(handlePageID).appendMessage(
          msg: res.choices[0].delta.content,
          reasoning_content: j["choices"][0]["delta"]["reasoning_content"] ??
              '', //res.choices[0].delta.reasoning_content,
          toolCalls: res.choices[0].delta.toolCalls,
        );

    if (res.choices[0].finishReason ==
        openai.ChatCompletionFinishReason.toolCalls) {
      pages.getPage(handlePageID).setOpenaiToolInput();
      ChatAPI().submitText(pages, property, handlePageID, user);
    }
  }

  static void Gemini(Pages pages, Property property, User user,
      int handlePageID, Map<String, dynamic> j) {
    var res = gemini.GenerateContentResponse.fromJson(j);

    pages.getPage(handlePageID).appendMessage(
          msg: res.candidates?.first.content?.parts?.first.text,
          // toolCalls: res.choices[0].delta.toolCalls,
        );

    // if (res.choices[0].finishReason ==
    //     openai.ChatCompletionFinishReason.toolCalls) {
    //   pages.getPage(handlePageID).setOpenaiToolInput();
    //   ChatAPI().submitText(pages, property, handlePageID, user);
    // }
  }
}
