import 'dart:convert';
import 'dart:typed_data';

import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:google_generative_ai/src/api.dart' as gemini;

class AIResponse {
  static void Openai(
    Pages pages,
    Property property,
    User user,
    int handlePageID,
    Map<String, dynamic> j,
    rp.WidgetRef ref,
  ) async {
    var res = openai.CreateChatCompletionStreamResponse.fromJson(j);

    if (res.choices.isNotEmpty) {
      pages.getPage(handlePageID).appendMessage(
            msg: res.choices[0].delta.content,
            toolCalls: res.choices[0].delta.toolCalls,
          );

      if (res.choices[0].finishReason ==
          openai.ChatCompletionFinishReason.toolCalls) {
        await pages.getPage(handlePageID).handleOpenaiToolCall(ref);
        ChatAPI().submitText(pages, property, handlePageID, user, ref);
      }
      if (res.choices[0].finishReason != null) {
        pages.setPageGenerateStatus(handlePageID, false);
        Logger.info("stoped: ${res.choices[0].finishReason}");
      }
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

    pages.getPage(handlePageID).messages.last.onProcessing = false;
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
          pages.setPageGenerateStatus(handlePageID, false);
          Logger.error("errorEvent: $data");
        },
        doneEvent: (final event, final data) {
          pages.setPageGenerateStatus(handlePageID, false);
          Logger.info("doneEvent");
        });

    pages.getPage(handlePageID).appendMessage(
        msg: _text,
        visionFiles: copyVision(visionFiles),
        attachments: copyAttachment(attachments));
    //pages.setGeneratingState(handlePageID, true);
  }

  static void Claude(
    Pages pages,
    Property property,
    User user,
    int handlePageID,
    Map<String, dynamic> j,
    rp.WidgetRef ref,
  ) {
    try {
      anthropic.MessageStreamEvent res =
          anthropic.MessageStreamEvent.fromJson(j);
      res.whenOrNull(
        messageDelta: (anthropic.MessageDelta delta, type, usage) async {
          // if (delta.stopReason == anthropic.StopReason.toolUse) {
          //   await pages.getPage(handlePageID).setClaudeToolInput(i);
          // }
        },
        contentBlockStart:
            (anthropic.Block b, int i, anthropic.MessageStreamEventType t) {
          if (b.type == "tool_use") {
            pages.getPage(handlePageID).addMessageContent(
                  b.mapOrNull(
                    text: (x) => TextContent(text: x.text),
                    toolUse: (x) => anthropic.ToolUseBlock(
                      id: x.id,
                      name: x.name,
                      input: x.input,
                    ),
                  ),
                );
            // add an empty msg in content
            // pages.getPage(handlePageID).addMessage(
            //       role: MessageTRole.assistant,
            //       toolUse: b.mapOrNull(
            //         toolUse: (x) => anthropic.ToolUseBlock(
            //           id: x.id,
            //           name: x.name,
            //           input: x.input,
            //         ),
            //       ),
            //     );
          }
        },
        contentBlockDelta: (anthropic.BlockDelta b, int i,
            anthropic.MessageStreamEventType t) {
          pages.getPage(handlePageID).appendMessage(
                index: i,
                msg: b.mapOrNull(textDelta: (x) => x.text),
                toolUse: b.mapOrNull(inputJsonDelta: (x) => x.partialJson),
              );
        },
        contentBlockStop: (int i, anthropic.MessageStreamEventType t) async {
          if (pages.getPage(handlePageID).messages.last.content is List &&
              pages.getPage(handlePageID).messages.last.content[i].type ==
                  "tool_use") {
            await pages.getPage(handlePageID).handleClaudeToolCall(i);
            ChatAPI().submitText(pages, property, handlePageID, user, ref);
          }
        },
        messageStop: (type) {
          pages.setPageGenerateStatus(handlePageID, false);
          Logger.info("${type}");
        },
        error: (anthropic.MessageStreamEventType type, error) {
          pages.setPageGenerateStatus(handlePageID, false);
          Logger.error("error: type: ${type}, err: $error");
        },
      );
    } catch (e) {
      pages.setPageGenerateStatus(handlePageID, false);
      pages.getPage(handlePageID).appendMessage(
            msg: j.toString() + e.toString(),
          );
    }
  }

  static void DeepSeek(
    Pages pages,
    Property property,
    User user,
    int handlePageID,
    Map<String, dynamic> j,
    rp.WidgetRef ref,
  ) async {
    var res = openai.CreateChatCompletionStreamResponse.fromJson(j);
    if (res.choices.isNotEmpty) {
      pages.getPage(handlePageID).appendMessage(
            msg: res.choices[0].delta.content,
            reasoning_content: j["choices"][0]["delta"]["reasoning_content"] ??
                null, //res.choices[0].delta.reasoning_content,
            toolCalls: res.choices[0].delta.toolCalls,
          );

      if (res.choices[0].finishReason ==
          openai.ChatCompletionFinishReason.toolCalls) {
        await pages.getPage(handlePageID).handleOpenaiToolCall(ref);
        ChatAPI().submitText(pages, property, handlePageID, user, ref);
      }
      if (res.choices[0].finishReason != null) {
        pages.setPageGenerateStatus(handlePageID, false);
      }
    }
  }

  static void Gemini(
    Pages pages,
    Property property,
    User user,
    int handlePageID,
    Map<String, dynamic> j,
    rp.WidgetRef ref,
  ) async {
    var res = gemini.parseGenerateContentResponse(j);

    await pages.getPage(handlePageID).appendMessage(msg: res.text);
    if (res.image != null) {
      var ts = DateTime.now().millisecondsSinceEpoch;
      String extension = res.image!.mimeType.split('/').last;
      String imgname = "ai$ts.${extension}";
      //////need to decode again
      String secondBase64 = utf8.decode(res.image!.bytes);
      Uint8List secondDecode = base64Decode(secondBase64);
      //////
      await pages.getPage(handlePageID).appendMessage(
        visionFiles: {
          "$imgname": VisionFile(
            name: imgname,
            bytes: secondDecode,
          ),
        },
      );
    }

    //gemini function call response is one time, not stream
    if (res.functionCalls.isNotEmpty && res.functionCalls.isNotEmpty) {
      await pages
          .getPage(handlePageID)
          .handleGeminiToolCall(res.functionCalls.first);
      ChatAPI().submitText(pages, property, handlePageID, user, ref);
      // pages.getPage(handlePageID).addMessage(
      //       role: MessageTRole.tool,
      //       text: "function response",
      //     );
      // ChatAPI().submitText(pages, property, handlePageID, user);
    }
  }
}
