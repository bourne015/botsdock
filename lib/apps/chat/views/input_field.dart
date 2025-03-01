import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/data.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import '../vendor/assistants_api.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final ChatAPI chats = ChatAPI();
  final _controller = TextEditingController();
  bool _hasInputContent = false;

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
    Property property = Provider.of<Property>(context);
    bool _userReady = isUserReady(user);
    double _hmargin =
        isDisplayDesktop(context) ? (property.isDrawerOpen ? 100 : 180) : 50;

    return AnimatedContainer(
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 270),
      decoration: BoxDecoration(
          color: AppColors.inputBoxBackground,
          border: Border.all(color: Colors.grey[350]!, width: 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: EdgeInsets.fromLTRB(_hmargin, 5, _hmargin, 25),
      child: Row(
        children: [
          _userReady
              ? pickButton(context)
              : IconButton(
                  onPressed: null, icon: Icon(Icons.attachment, size: 20)),
          inputField(context),
          _userReady
              ? Selector<Pages, bool>(
                  selector: (_, pages) =>
                      pages.getPageGenerateStatus(pages.currentPageID),
                  builder: (context, isGenerating, child) {
                    if (isGenerating) return generatingAnimation(context);
                    return sendButton(context);
                  },
                )
              : lockButton(context, user),
        ],
      ),
    );
  }

  Widget inputField(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context);
    User user = Provider.of<User>(context);
    return Expanded(
        child: Column(children: [
      if (attachments.isNotEmpty)
        Container(height: 70, child: attachmentsList(context)),
      if (visionFiles.isNotEmpty)
        Container(height: 70, child: visionFilesList(context)),
      isDisplayDesktop(context)
          ? KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter &&
                      HardwareKeyboard.instance.isControlPressed &&
                      isUserReady(user) &&
                      isContentReady(pages, property))
                    _sendContent(pages, property, user);
                }
              },
              child: textField(context),
            )
          : textField(context),
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
        leading: content.file_id!.isEmpty && content.file_url!.isEmpty
            ? Container(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.description_outlined, color: Colors.pink[300]),
        trailing: IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                var _fileid = content.file_id;
                attachments.remove(name);

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
    String hintText = "text, image, file";
    var _modelV;
    if (property.onInitPage)
      _modelV = property.initModelVersion;
    else
      _modelV = pages.currentPage?.model;
    if (_modelV == GPTModel.gptv35 ||
        _modelV == DeepSeekModel.dc ||
        _modelV == DeepSeekModel.dc_r) {
      hintText = "send a message";
    } else if (_modelV == GPTModel.gptv40Dall) {
      hintText = "describe the image";
    }

    return TextFormField(
      onChanged: (value) {
        if (_hasInputContent && value.isEmpty) {
          setState(() {
            _hasInputContent = false;
          });
        } else if (!_hasInputContent && value.isNotEmpty) {
          setState(() {
            _hasInputContent = true;
          });
        }
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

  Widget _pickMenu(BuildContext context, String modelV) {
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
            _pickFile(modelV);
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
    if (DeepSeekModel.all.contains(_modelV)) return const SizedBox(width: 15);
    if (_modelV == GPTModel.gptv40Dall) return const SizedBox(width: 15);
    if (_modelV == GPTModel.gptvo1mini) return const SizedBox(width: 15);
    if (GPTModel.all.contains(_modelV) &&
        !property.onInitPage &&
        pages.currentPage!.assistantID == null) {
      return IconButton(
          tooltip: "选择图片",
          icon: Icon(Icons.image_rounded, size: 20),
          onPressed: _pickImage);
    }
    return _pickMenu(context, _modelV);
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

  bool isUserReady(User user) {
    return (user.isLogedin && user.credit! > 0) ? true : false;
  }

  bool isContentReady(Pages pages, Property property) {
    bool isReady = false;
    if (_hasInputContent &&
        (property.onInitPage || !pages.currentPage!.onGenerating))
      isReady = true;
    return isReady;
  }

  Widget sendButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context);
    User user = Provider.of<User>(context);
    bool _enabled = isContentReady(pages, property);

    return IconButton(
      icon: const Icon(Icons.send),
      color: _enabled ? Colors.blue : Colors.grey,
      tooltip: _enabled ? "Ctrl+Enter发送" : "",
      onPressed: _enabled
          ? () async {
              _sendContent(pages, property, user);
            }
          : () {},
    );
  }

  void _sendContent(pages, property, User user) async {
    int newPageId = -1;

    if (property.onInitPage) {
      String? thread_id = null;
      if (GPTModel.all.contains(property.initModelVersion) &&
          attachments.isNotEmpty) thread_id = await assistant.createThread();
      if (thread_id != null) {
        newPageId = assistant.newassistant(pages, property, user, thread_id,
            ass_id: chatAssistantID);
      } else {
        newPageId = pages.addPage(
          Chat(
            title: "Chat 0",
            model: property.initModelVersion,
            artifact: user.settings?.artifact ?? false,
            internet: user.settings?.internet ?? false,
          ),
          sort: true,
        );
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
  }

  /**
   * pick image and save for vision
   */
  Future<void> _pickImage() async {
    var result;

    result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: supportedImages);

    if (result != null) {
      final fileName = result.files.first.name;

      if (result.files.first.size / (1024 * 1024) > maxFileMBSize) {
        showMessage(context, "文件大小超过限制:${maxFileMBSize}MB");
        return;
      } else {
        debugPrint('Selected file: $fileName');

        setState(() {
          visionFiles[fileName] = VisionFile(
            name: fileName,
            bytes: result.files.first.bytes,
          );
        });
      }
    } else {
      debugPrint('No file selected.');
    }
  }

/**
 * pick all supported file(image and textfile) and save to attachment
 */
  Future<void> _pickFile(String modelV) async {
    var result;
    var _spf = supportedFilesAll;
    if (ClaudeModel().toJson().containsKey(modelV))
      _spf = claudeSupportedFiles;
    else if (GeminiModel().toJson().containsKey(modelV))
      _spf = geminiSupportedFiles;

    result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: _spf);

    if (result != null) {
      final fileName = result.files.first.name;

      if (result.files.first.size / (1024 * 1024) > maxFileMBSize) {
        showMessage(context, "文件大小超过限制:${maxFileMBSize}MB");
      } else {
        debugPrint('Selected file: $fileName');
        setState(() {
          attachments[fileName] = Attachment();
        });

        _uploadPickedFiles(result, modelV);
      }
    } else {
      debugPrint('No file selected.');
    }
  }

  Future<void> _uploadPickedFiles(selectedfile, String modelV) async {
    String? _file_id;
    String? _file_url;
    if (GPTModel.all.contains(modelV)) {
      await assistant.uploadFile(selectedfile);
      _file_id = await assistant.fileUpload(selectedfile.files.first.name);
      attachments[selectedfile.files.first.name]!.file_id = _file_id;
      attachments[selectedfile.files.first.name]!.tools = [
        {"type": "file_search"},
        {"type": "code_interpreter"},
      ];
    } else if (ClaudeModel().toJson().containsKey(modelV)) {
      _file_url = await chats.uploadFile(
          selectedfile.files.first.name, selectedfile.files.first.bytes);
    } else if (GeminiModel().toJson().containsKey(modelV)) {
      _file_url = await chats.uploadFile(
          selectedfile.files.first.name, selectedfile.files.first.bytes);
    }
    setState(() {
      attachments[selectedfile.files.first.name]!.file_name =
          selectedfile.files.first.name;
      attachments[selectedfile.files.first.name]!.file_url = _file_url ?? '';
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

      //we save image bytes in visionFiles for quick display
      //here we upload images to oss and save url in messages and visionFiles
      if (visionFiles.isNotEmpty) {
        for (var entry in _vf.entries) {
          var _filename = entry.key;
          var _content = entry.value;
          String oss_name = "user${user.id}_${handlePageID}_${ts}" + _filename;
          String? ossURL = await chats.uploadFile(oss_name, _content.bytes);
          _content.url = ossURL ?? "";
          pages
              .getPage(handlePageID)
              .messages[msg_id]
              .updateImageURL(ossURL ?? "");
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
