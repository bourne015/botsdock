import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/models/user.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import '../utils/assistants_api.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final ChatGen chats = ChatGen();
  final _controller = TextEditingController();
  bool _hasInputContent = false;
  String? _fileName;
  MsgType _type = MsgType.text;
  List<int>? _fileBytes;
  final assistant = AssistantsAPI();
  final ScrollController _attachmentscroll = ScrollController();
  //{"file_name":
  //  {"file_id": file.id,
  //   "tools": [{"type": "file_search"}]}
  // }
  Map attachments = {};

  void dispose() {
    _attachmentscroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    User user = Provider.of<User>(context);
    var _modelV;
    if (property.onInitPage)
      _modelV = property.initModelVersion;
    else
      _modelV = pages.currentPage?.modelVersion;
    var _picButtonImg = Icons.image_rounded;
    var _picButtonTip = "选择图片";
    if (!property.onInitPage && pages.currentPage!.assistantID != null) {
      _picButtonImg = Icons.attachment;
      _picButtonTip = "选择文件";
    }

    return Container(
      decoration: BoxDecoration(
          color: AppColors.inputBoxBackground,
          border: Border.all(color: Colors.grey[350]!, width: 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.fromLTRB(70, 5, 70, 25),
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 4),
      child: Row(
        children: [
          if (_modelV != GPTModel.gptv35 && _modelV != GPTModel.gptv40Dall)
            pickButton(context, _picButtonTip, _picButtonImg)
          else
            const SizedBox(
              width: 15,
            ),
          inputField(context),
          !user.isLogedin || user.credit! <= 0
              ? lockButton(context, user)
              : (!property.onInitPage && pages.currentPage!.onGenerating)
                  ? generatingAnimation(context)
                  : sendButton(context),
        ],
      ),
    );
  }

  Widget inputField(BuildContext context) {
    return Expanded(
        child: Column(children: [
      attathmentField(context),
      const SizedBox(width: 8),
      textField(context),
    ]));
  }

  Widget attachedFileIcon(
      BuildContext context, String attachedFileName, attachFile) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
          color: AppColors.chatPageBackground,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: ListTile(
        dense: true,
        title: Text(attachedFileName, overflow: TextOverflow.ellipsis),
        leading: attachments[attachedFileName].isEmpty
            ? CircularProgressIndicator()
            : Icon(Icons.description_outlined, color: Colors.pink[300]),
        trailing: IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                var _fileid = attachments[attachedFileName]["file_id"];
                attachments.remove(attachedFileName);
                if (attachments.isEmpty) _type = MsgType.text;
                assistant.filedelete(_fileid); //TODO: delete in backend
              });
            }),
      ),
    );
  }

  Widget attachedImageIcon(BuildContext context) {
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
                _type = MsgType.text;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget attachmentList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 3);
    final double childAspectRatio = (width / crossAxisCount) / 80.0;
    final hpaddng = isDisplayDesktop(context) ? 15.0 : 15.0;
    return GridView.builder(
      key: UniqueKey(),
      controller: _attachmentscroll,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: hpaddng, vertical: 5),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 20.0,
        childAspectRatio: childAspectRatio,
        crossAxisCount: crossAxisCount,
      ),
      itemCount: attachments.entries.length,
      itemBuilder: (BuildContext context, int index) {
        MapEntry entry = attachments.entries.elementAt(index);
        return attachedFileIcon(context, entry.key, entry.value);
      },
    );
  }

  Widget attathmentField(BuildContext context) {
    if (_type == MsgType.text) return Container();
    if (_type == MsgType.file)
      return Container(height: 70, child: attachmentList(context));
    return attachedImageIcon(context);
  }

  Widget textField(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    String hintText = "text, image, text file";
    var _modelV;
    if (property.onInitPage)
      _modelV = property.initModelVersion;
    else
      _modelV = pages.currentPage?.modelVersion;
    if (_modelV == GPTModel.gptv35) {
      hintText = "Send a message";
    } else if (_modelV == GPTModel.gptv40Dall) {
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

  Widget pickButton(BuildContext context, picButtonTip, picButtonImg) {
    return IconButton(
        tooltip: picButtonTip,
        icon: Icon(
          picButtonImg,
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

  Widget lockButton(BuildContext context, User user) {
    var _tooltip;
    if (!user.isLogedin)
      _tooltip = "请登录";
    else
      _tooltip = "余额不足,请充值";
    return IconButton(
      icon: const Icon(Icons.lock_person_outlined),
      tooltip: _tooltip,
      color: Colors.grey,
      onPressed: null,
    );
  }

  bool isContentReady(Pages pages, Property property) {
    bool isReady = false;
    if ((_fileName != null || _hasInputContent) &&
        (property.onInitPage ||
            (pages.currentPageID >= 0 && !pages.currentPage!.onGenerating)))
      isReady = true;
    return isReady;
  }

  Widget sendButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);
    User user = Provider.of<User>(context);
    return IconButton(
      icon: const Icon(Icons.send),
      color: isContentReady(pages, property) ? Colors.blue : Colors.grey,
      onPressed: isContentReady(pages, property)
          ? () {
              int newPageId;
              if (property.onInitPage) {
                newPageId = pages.addPage(Chat(title: "Chat 0"), sort: true);
                property.onInitPage = false;
                pages.currentPageID = newPageId;
                pages.currentPage?.modelVersion = property.initModelVersion;
              } else {
                newPageId = pages.currentPageID;
              }
              _submitText(pages, property, newPageId, _controller.text, user);
              _controller.clear();
              _hasInputContent = false;
              //_fileName = null;
              attachments.clear();
              _type = MsgType.text;
            }
          : () {},
    );
  }

  Future<void> _pickFile() async {
    var result;
    if (kIsWeb) {
      debugPrint('web platform');
      result = await FilePickerWeb.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedFiles1);
    } else {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedFiles1);
    }
    if (result != null) {
      final fileName = result.files.first.name;
      setState(() {
        attachments[fileName] = {};
      });
      String fileType = fileName.split('.').last.toLowerCase();
      debugPrint('Selected file: $fileName, type: $fileType');
      if (supportedFiles.contains(fileType)) {
        _type = MsgType.file;
        _getTextFile(result);
      } else if (supportedImageFiles.contains(fileType)) {
        _type = MsgType.image;
        _getImage(result);
      } else {
        print("unknow");
      }
    } else {
      debugPrint('No file selected.');
    }
  }

  Future<void> _getTextFile(selectedfile) async {
    await assistant.uploadFile(selectedfile);
    String file_id = await assistant.fileUpload(selectedfile.files.first.name);
    setState(() {
      attachments[selectedfile.files.first.name] = {
        "file_id": file_id,
        "tools": [
          //TODO: add code_interpreters
          {"type": "file_search"}
        ]
      };
    });
  }

  Future<void> _getImage(imagefile) async {
    setState(() {
      _fileName = imagefile.files.first.name;
    });
    _fileBytes = imagefile.files.first.bytes;
  }

  Map deepCopy(Map original) {
    Map copy = {};
    original.forEach((key, value) {
      if (value is Map)
        copy[key] = deepCopy(value);
      else if (value is List)
        copy[key] = deepCopyList(value);
      else
        copy[key] = value;
    });
    return copy;
  }

  List deepCopyList(List original) {
    List copy = [];
    original.forEach((element) {
      if (element is Map)
        copy.add(deepCopy(element));
      else if (element is List)
        copy.add(deepCopyList(element));
      else
        copy.add(element);
    });
    return copy;
  }

  void _submitText(Pages pages, Property property, int handlePageID,
      String text, User user) async {
    try {
      pages.getPage(handlePageID).onGenerating = true;
      var ts = DateTime.now().millisecondsSinceEpoch;
      Message msgQ = Message(
          id: pages.getPage(handlePageID).messages.length,
          pageID: handlePageID,
          role: MessageRole.user,
          type: _type,
          content: text,
          fileName: _fileName,
          fileBytes: _fileBytes,
          //fileUrl: ossUrl,
          attachments: deepCopy(attachments),
          timestamp: ts);
      pages.addMessage(handlePageID, msgQ);
      if (_type == MsgType.image && _fileBytes != null) {
        String oss_name = "user${user.id}_${handlePageID}_${ts}" + _fileName!;
        chats.uploadImage(pages, handlePageID, msgQ.id, oss_name, _fileBytes);
      }
    } catch (e) {
      debugPrint("_submitText error: $e");
      pages.getPage(handlePageID).onGenerating = false;
    }
    if (pages.getPage(handlePageID).assistantID != null)
      chats.submitAssistant(pages, property, handlePageID, user, attachments);
    else
      chats.submitText(pages, property, handlePageID, user);
  }
}
