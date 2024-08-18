import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery/apps/chat/models/user.dart';
import 'package:gallery/apps/chat/utils/custom_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/data.dart';
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
  MsgType _type = MsgType.text;
  final assistant = AssistantsAPI();
  final ScrollController _attachmentscroll = ScrollController();
  final ScrollController _visionFilescroll = ScrollController();

  Map<String, Attachment> attachments = {};
  Map<String, VisionFile> visionFiles = {};

  void dispose() {
    _attachmentscroll.dispose();
    _visionFilescroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User user = Provider.of<User>(context);

    return Container(
      decoration: BoxDecoration(
          color: AppColors.inputBoxBackground,
          border: Border.all(color: Colors.grey[350]!, width: 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.fromLTRB(70, 5, 70, 25),
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 4),
      child: Row(
        children: [
          !user.isLogedin || user.credit! <= 0
              ? IconButton(
                  onPressed: null,
                  icon: Icon(Icons.attachment, size: 20),
                )
              : pickButton(context),
          inputField(context),
          !user.isLogedin || user.credit! <= 0
              ? lockButton(context, user)
              : Selector<Pages, bool>(
                  selector: (_, pages) =>
                      pages.getPageGenerateStatus(pages.currentPageID),
                  builder: (context, isGenerating, child) {
                    if (isGenerating) return generatingAnimation(context);
                    return sendButton(context);
                  },
                ),
        ],
      ),
    );
  }

  Widget inputField(BuildContext context) {
    return Expanded(
        child: Column(children: [
      if (attachments.isNotEmpty)
        Container(height: 70, child: attachmentsList(context)),
      if (visionFiles.isNotEmpty)
        Container(height: 70, child: visionFilesList(context)),
      textField(context),
    ]));
  }

  Widget attachedFileIcon(
      BuildContext context, String name, Attachment content) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
          color: AppColors.chatPageBackground,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: ListTile(
        dense: true,
        title: Text(name, overflow: TextOverflow.ellipsis),
        leading: content.file_id!.isEmpty
            ? CircularProgressIndicator()
            : Icon(Icons.description_outlined, color: Colors.pink[300]),
        trailing: IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                var _fileid = content.file_id;
                attachments.remove(name);
                if (attachments.isEmpty) _type = MsgType.text;
                assistant.filedelete(_fileid); //TODO: delete in backend
              });
            }),
      ),
    );
  }

  Widget attachedImageIcon(BuildContext context, _name, _content) {
    return Container(
      decoration: BoxDecoration(
          //color: AppColors.inputBoxBackground,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.all(1),
      child: Row(
        children: [
          Image.memory(Uint8List.fromList(_content.bytes),
              height: 60, width: 60, fit: BoxFit.cover),
          Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 12),
                onPressed: () {
                  setState(() {
                    visionFiles.remove(_name); //TODO: delete in oss
                    if (visionFiles.isEmpty) _type = MsgType.text;
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget attachmentsList(BuildContext context) {
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

  Widget visionFilesList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = (width ~/ 300).clamp(1, 6);
    final double childAspectRatio = (width / crossAxisCount) / 110.0;
    final hpaddng = isDisplayDesktop(context) ? 15.0 : 15.0;
    return GridView.builder(
      key: UniqueKey(),
      controller: _visionFilescroll,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: hpaddng, vertical: 5),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 20.0,
        childAspectRatio: childAspectRatio,
        crossAxisCount: crossAxisCount,
      ),
      itemCount: visionFiles.entries.length,
      itemBuilder: (BuildContext context, int index) {
        MapEntry entry = visionFiles.entries.elementAt(index);
        return attachedImageIcon(context, entry.key, entry.value);
      },
    );
  }

  Widget textField(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    String hintText = "text, image, text file";
    var _modelV;
    if (property.onInitPage)
      _modelV = property.initModelVersion;
    else
      _modelV = pages.currentPage?.model;
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

  PopupMenuItem<String> _buildPopupMenuItem(BuildContext context, String value,
      {Icon? icon, String? title, void Function()? onTap}) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.all(0),
      value: value,
      child: Material(
        color: AppColors.drawerBackground,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(borderRadius: BORDERRADIUS15),
            child: InkWell(
              borderRadius: BORDERRADIUS15,
              onTap: onTap,
              child: ListTile(
                  contentPadding: EdgeInsets.only(left: 5),
                  leading: icon,
                  title: Text(title ?? "")),
            )),
      ),
    );
  }

  Widget _pickMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.attachment, size: 20),
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      position: PopupMenuPosition.over,
      padding: const EdgeInsets.only(left: 2),
      shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS10),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(
          context,
          "image",
          icon: Icon(Icons.image_rounded, size: 14),
          title: "选择图片",
          onTap: () {
            Navigator.of(context).pop();
            _pickImage();
          },
        ),
        PopupMenuDivider(height: 1.0),
        _buildPopupMenuItem(
          context,
          "file",
          icon: Icon(Icons.attachment, size: 14),
          title: "选择文件",
          onTap: () {
            Navigator.of(context).pop();
            _pickAll();
          },
        ),
      ],
    );
  }

  Widget pickButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    Property property = Provider.of<Property>(context);

    String _modelV;
    if (property.onInitPage)
      _modelV = property.initModelVersion;
    else
      _modelV = pages.currentPage!.model;

    if (_modelV.startsWith('gpt-3')) return const SizedBox(width: 15);
    if (!property.onInitPage && pages.currentPage!.assistantID == null) {
      return IconButton(
          tooltip: "选择图片",
          icon: Icon(Icons.image_rounded, size: 20),
          onPressed: _pickImage);
    }
    if (_modelV.startsWith('gpt-4'))
      return _pickMenu(context);
    else if (_modelV.startsWith('claude'))
      return IconButton(
          tooltip: "选择图片",
          icon: Icon(Icons.image_rounded, size: 20),
          onPressed: _pickImage);
    else
      return const SizedBox(width: 15);
  }

  Widget generatingAnimation(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(right: 7),
        child: const SpinKitDoubleBounce(
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
    if ((visionFiles.isNotEmpty ||
            attachments.isNotEmpty ||
            _hasInputContent) &&
        (property.onInitPage ||
            (pages.currentPageID >= 0 && !pages.currentPage!.onGenerating)))
      isReady = true;
    return isReady;
  }

  Widget sendButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context);
    User user = Provider.of<User>(context);
    return IconButton(
      icon: const Icon(Icons.send),
      color: isContentReady(pages, property) ? Colors.blue : Colors.grey,
      onPressed: isContentReady(pages, property)
          ? () async {
              int newPageId = -1;
              if (property.onInitPage) {
                String? thread_id = null;
                if (attachments.isNotEmpty)
                  thread_id = await assistant.createThread();
                if (thread_id != null) {
                  newPageId = assistant.newassistant(
                      pages, property, user, thread_id,
                      ass_id: chatAssistantID);
                } else {
                  newPageId = pages.addPage(
                      Chat(title: "Chat 0", model: property.initModelVersion),
                      sort: true);
                  property.onInitPage = false;
                  pages.currentPageID = newPageId;
                }
              } else {
                newPageId = pages.currentPageID;
              }
              _submitText(pages, property, newPageId, _controller.text, user);
              _controller.clear();
              _hasInputContent = false;
              attachments.clear();
              visionFiles.clear();
              _type = MsgType.text;
            }
          : () {},
    );
  }

  /**
   * pick image and save for vision
   */
  Future<void> _pickImage() async {
    var result;

    if (kIsWeb) {
      debugPrint('web platform');
      result = await FilePickerWeb.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedImages);
    } else {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: supportedImages);
    }
    if (result != null) {
      final fileName = result.files.first.name;

      if (result.files.first.size / (1024 * 1024) > maxFileMBSize) {
        showMessage(context, "文件大小超过限制:${maxFileMBSize}MB");
        return;
      } else {
        debugPrint('Selected file: $fileName');
        _type = MsgType.image;
        setState(() {
          visionFiles[fileName] = VisionFile(name: fileName);
        });
        _getImage(result);
      }
    } else {
      debugPrint('No file selected.');
    }
  }

/**
 * pick all supported file(image and textfile) and save to attachment
 */
  Future<void> _pickAll() async {
    var result;

    if (kIsWeb) {
      debugPrint('web platform');
      result = await FilePickerWeb.platform.pickFiles(
          type: FileType.custom, allowedExtensions: supportedFilesAll);
    } else {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: supportedFilesAll);
    }
    if (result != null) {
      final fileName = result.files.first.name;

      if (result.files.first.size / (1024 * 1024) > maxFileMBSize) {
        showMessage(context, "文件大小超过限制:${maxFileMBSize}MB");
      } else {
        debugPrint('Selected file: $fileName');
        setState(() {
          attachments[fileName] = Attachment();
        });
        _type = MsgType.file;
        _getTextFile(result);
      }
    } else {
      debugPrint('No file selected.');
    }
  }

  Future<void> _pickFile() async {
    var result;
    var _supported;
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    var _modelV;
    if (property.onInitPage)
      _modelV = property.initModelVersion;
    else
      _modelV = pages.currentPage?.model;
    if (_modelV.startsWith("gpt-4"))
      _supported = supportedFilesAll;
    else if (_modelV.startsWith("gpt-3"))
      _supported = supportedFiles;
    else
      _supported = supportedImages;
    if (kIsWeb) {
      debugPrint('web platform');
      result = await FilePickerWeb.platform
          .pickFiles(type: FileType.custom, allowedExtensions: _supported);
    } else {
      result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: _supported);
    }
    if (result != null) {
      final fileName = result.files.first.name;

      if (result.files.first.size / (1024 * 1024) > maxFileMBSize) {
        showMessage(context, "文件大小超过限制:${maxFileMBSize}MB");
        return;
      }
      String fileType = fileName.split('.').last.toLowerCase();
      debugPrint('Selected file: $fileName, type: $fileType');
      if (supportedFiles.contains(fileType) ||
          supportedFiles_cp.contains(fileType)) {
        setState(() {
          attachments[fileName] = Attachment();
        });
        _type = MsgType.file;
        _getTextFile(result);
      } else if (supportedImages.contains(fileType)) {
        _type = MsgType.image;
        setState(() {
          visionFiles[fileName] = VisionFile(name: fileName);
        });
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
      attachments[selectedfile.files.first.name]!.file_id = file_id;
      attachments[selectedfile.files.first.name]!.tools = [
        {"type": "file_search"},
        {"type": "code_interpreter"},
      ];
    });
  }

  Future<void> _getImage(selectedfile) async {
    setState(() {
      visionFiles[selectedfile.files.first.name]!.bytes =
          selectedfile.files.first.bytes;
    });
  }

  void _submitText(Pages pages, Property property, int handlePageID,
      String text, User user) async {
    try {
      pages.setGeneratingState(handlePageID, true);
      var ts = DateTime.now().millisecondsSinceEpoch;
      Map<String, VisionFile> _vf = copyVision(visionFiles);
      int msg_id = pages.getPage(handlePageID).addMessage(
            role: MessageTRole.user,
            text: text,
            visionFiles: _vf,
            attachments: copyAttachment(attachments),
          );
      if (visionFiles.isNotEmpty) {
        for (var entry in _vf.entries) {
          var _filename = entry.key;
          var _content = entry.value;
          print("get file: $_filename");
          String oss_name = "user${user.id}_${handlePageID}_${ts}" + _filename;
          String? ossURL = await chats.uploadImage(
              pages, handlePageID, oss_name, _filename, _content.bytes);
          if (!pages.getPage(handlePageID).model.startsWith("claude")) {
            // claude vison don't support url,
            _content.url = ossURL ?? "";
            pages
                .getPage(handlePageID)
                .messages[msg_id]
                .updateImageURL(ossURL ?? "");
          }
          if (pages.getPage(handlePageID).model.startsWith("claude"))
            pages
                .getPage(handlePageID)
                .messages[msg_id]
                .updateVisionFiles(_filename, ossURL ?? "");
        }
      }
    } catch (e) {
      debugPrint("_submitText error: $e");
      pages.setGeneratingState(handlePageID, false);
    }
    if (pages.getPage(handlePageID).assistantID != null)
      chats.submitAssistant(pages, property, handlePageID, user, attachments);
    else
      chats.submitText(pages, property, handlePageID, user);
  }
}
