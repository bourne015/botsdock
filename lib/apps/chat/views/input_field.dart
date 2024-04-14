import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/models/user.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import '../utils/global.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final dio = Dio();
  final ChatSSE chatServer = ChatSSE();
  final _controller = TextEditingController();
  bool _hasInputContent = false;
  String? _fileName;
  MsgType _type = MsgType.text;
  List<int>? _fileBytes;

  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Container(
      decoration: BoxDecoration(
          //color: AppColors.inputBoxBackground,
          border: Border.all(color: Colors.grey[350]!, width: 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.fromLTRB(70, 5, 70, 25),
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 4),
      child: Row(
        children: [
          if ((!pages.displayInitPage &&
                  (pages.currentPage?.modelVersion == GPTModel.gptv40Vision ||
                      pages.currentPage?.modelVersion.substring(0, 6) ==
                          "claude")) ||
              (pages.displayInitPage &&
                  (pages.defaultModelVersion == GPTModel.gptv40Vision ||
                      pages.defaultModelVersion.substring(0, 6) == "claude")))
            pickButton(context)
          else
            const SizedBox(
              width: 15,
            ),
          inputField(context),
          (!pages.displayInitPage && pages.currentPage!.onGenerating)
              ? generatingAnimation(context)
              : sendButton(context),
        ],
      ),
    );
  }

  Widget inputField(BuildContext context) {
    return Expanded(
        child: Stack(alignment: Alignment.topLeft, children: <Widget>[
      Column(children: [
        fileField(context),
        const SizedBox(width: 8),
        textField(context),
      ]),
    ]));
  }

  Widget fileField(BuildContext context) {
    if (_type == null || _type == MsgType.text) {
      return Container();
    }
    if (_type == MsgType.file) {
      return Container(
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
            //color: AppColors.inputBoxBackground,
            borderRadius: const BorderRadius.all(Radius.circular(15))),
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(1),
        child: InputChip(
          side: BorderSide.none,
          label: Text(_fileName!),
          avatar: const Icon(
            Icons.file_copy_outlined,
            size: 15,
          ),
          onPressed: () {},
          onDeleted: () {
            setState(() {
              _fileName = null;
            });
          },
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
          //color: AppColors.inputBoxBackground,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(1),
      child: Row(
        children: [
          Image.memory(Uint8List.fromList(_fileBytes!),
              height: 60, width: 60, fit: BoxFit.cover),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 12,
            ),
            onPressed: () {
              setState(() {
                _fileName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget textField(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    String hintText = "Send a message";

    if ((pages.displayInitPage &&
            (pages.defaultModelVersion == GPTModel.gptv40Vision ||
                pages.defaultModelVersion.substring(0, 6) == 'claude')) ||
        (!pages.displayInitPage &&
            (pages.currentPage!.modelVersion == GPTModel.gptv40Vision ||
                pages.currentPage?.modelVersion.substring(0, 6) == "claude"))) {
      hintText = "input text, image or text file";
    } else if ((pages.displayInitPage &&
            pages.defaultModelVersion == GPTModel.gptv40Dall) ||
        (!pages.displayInitPage &&
            pages.currentPage!.modelVersion == GPTModel.gptv40Dall)) {
      hintText = "describe the image";
    }

    return TextFormField(
      onChanged: (value) {
        setState(() {
          _hasInputContent = value.isNotEmpty;
        });
      },
      decoration: InputDecoration(
          //filled: true,
          //fillColor: AppColors.inputBoxBackground,
          border: InputBorder.none,
          hintText: hintText),
      minLines: 1,
      maxLines: 10,
      textInputAction: TextInputAction.newline,
      controller: _controller,
    );
  }

  Widget pickButton(BuildContext context) {
    return IconButton(
        icon: const Icon(
          Icons.attach_file,
          size: 20,
        ),
        onPressed: _pickFile);
  }

  Widget generatingAnimation(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(right: 7),
        child: const SpinKitSpinningLines(
          color: AppColors.generatingAnimation,
          size: AppSize.generatingAnimation,
        ));
  }

  Widget sendButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    User user = Provider.of<User>(context);
    return IconButton(
      icon: const Icon(Icons.send),
      color: ((_fileName != null || _hasInputContent) &&
              (pages.displayInitPage ||
                  (pages.currentPageID >= 0 &&
                      !pages.currentPage!.onGenerating)))
          ? Colors.blue
          : Colors.grey,
      onPressed: ((_fileName != null || _hasInputContent) &&
              (pages.displayInitPage ||
                  (pages.currentPageID >= 0 &&
                      !pages.currentPage!.onGenerating)))
          ? () {
              int handlePageID;
              if (pages.currentPageID == -1) {
                handlePageID = pages.assignNewPageID;
                pages.currentPageID = handlePageID;
                pages.addPage(handlePageID,
                    Chat(chatId: handlePageID, title: "Chat $handlePageID"));
                pages.displayInitPage = false;
                pages.currentPage?.modelVersion = pages.defaultModelVersion;
              } else {
                handlePageID = pages.currentPageID;
              }
              _submitText(pages, handlePageID, _controller.text, user);
              _hasInputContent = false;
              _fileName = null;
            }
          : () {},
    );
  }

  Future<void> _pickFile() async {
    var result;
    if (kIsWeb) {
      debugPrint('web platform');
      result = await FilePickerWeb.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedFiles);
    } else {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedFiles);
    }
    if (result != null) {
      final fileName = result.files.first.name;
      debugPrint('Selected file: $fileName');
      String fileType = fileName.split('.').last.toLowerCase();
      debugPrint('Selected file type: $fileType');
      switch (fileType) {
        case 'txt':
        case 'md':
        case 'dart':
        case 'py':
        case 'c':
        case 'cpp':
        case 'h':
        case 'hpp':
        case 'java':
        case 'sh':
        case 'html':
        case 'css':
        case 'json':
          debugPrint('Text file');
          _type = MsgType.file;
          _getTextFile(result);
          break;
        case 'jpg':
        case 'png':
          _getImage(result);
          debugPrint('Image file: $fileType');
          _type = MsgType.image;
          break;
        case 'pdf':
          debugPrint('PDF file');
          break;
        case 'doc':
        case 'docx':
          debugPrint('Word file');
          break;
        default:
          debugPrint('unknow file');
      }
    } else {
      debugPrint('No file selected.');
    }
  }

  Future<void> _getTextFile(textfile) async {
    setState(() {
      _fileName = textfile.files.first.name;
    });
    _fileBytes = textfile.files.first.bytes;
  }

  Future<void> _getImage(imagefile) async {
    setState(() {
      _fileName = imagefile.files.first.name;
    });
    _fileBytes = imagefile.files.first.bytes;
  }

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
      var chatData1 = {
        "model": GPTModel.gptv35,
        "question": "为这段话写一个5个字左右的标题:$q"
      };
      final response = await dio.post(chatUrl, data: chatData1);
      var title = response.data;
      pages.setPageTitle(handlePageID, title);
    } catch (e) {
      debugPrint("titleGenerate error: $e");
    }
  }

  void _submitText(Pages pages, int handlePageID, String text, user) async {
    bool append = false;
    _controller.clear();

    Message msgQ = Message(
        id: '0',
        pageID: handlePageID,
        role: MessageRole.user,
        type: _type,
        content: text,
        fileName: _fileName,
        fileBytes: _fileBytes,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    pages.addMessage(handlePageID, msgQ);

    try {
      if (pages.defaultModelVersion == GPTModel.gptv40Dall) {
        String q = pages.getMessages(handlePageID)!.last.content;
        var chatData1 = {"model": GPTModel.gptv40Dall, "question": q};
        pages.getPage(handlePageID).onGenerating = true;
        final response = await dio.post(imageUrl, data: chatData1);
        pages.getPage(handlePageID).onGenerating = false;
        if (response.statusCode == 200 &&
            pages.getPage(handlePageID).title == "Chat $handlePageID") {
          titleGenerate(pages, handlePageID);
        }

        Message msgA = Message(
            id: '1',
            pageID: handlePageID,
            role: MessageRole.assistant,
            type: MsgType.image,
            content: response.data,
            timestamp: DateTime.now().millisecondsSinceEpoch);
        pages.addMessage(handlePageID, msgA);
      } else {
        var chatData = {
          "model": pages.currentPage?.modelVersion,
          "question": pages.getPage(handlePageID).gptMsgs,
        };
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
          if (append == false) {
            Message msgA = Message(
                id: '1',
                pageID: handlePageID,
                role: MessageRole.assistant,
                type: MsgType.text,
                content: data,
                timestamp: DateTime.now().millisecondsSinceEpoch);
            pages.addMessage(handlePageID, msgA);
          } else {
            pages.appendMessage(handlePageID, data);
          }
          pages.getPage(handlePageID).onGenerating = true;
          append = true;
        }, onError: (e) {
          debugPrint('SSE error: $e');
          pages.getPage(handlePageID).onGenerating = false;
        }, onDone: () async {
          debugPrint('SSE complete');
          if (pages.getPage(handlePageID).title == "Chat $handlePageID") {
            await titleGenerate(pages, handlePageID);
          }
          pages.getPage(handlePageID).onGenerating = false;
          if (user.id != 0) {
            //only store after user login
            var chatdbUrl = userUrl + "/" + "${user.id}" + "/chat";
            var chatData = {
              "id": pages.getPage(handlePageID).dbID,
              "title": pages.getPage(handlePageID).title,
              "contents": pages.getPage(handlePageID).msgsAll,
              "model": pages.getPage(handlePageID).modelVersion,
            };

            Response cres = await dio.post(
              chatdbUrl,
              data: chatData,
            );
            if (cres.data["result"] == "success") {
              pages.getPage(handlePageID).dbID = cres.data["id"];
            }
            chatData["id"] = cres.data["id"];
            Global.saveChats(user, cres.data["id"], jsonEncode(chatData));
            print("save: res id:${cres.data["id"]}, dataid:${chatData["id"]}");
          }
        });
      }
    } catch (e) {
      debugPrint("error: $e");
      pages.getPage(handlePageID).onGenerating = false;
    }
  }
}
