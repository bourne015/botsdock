import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:gallery/apps/chat/models/user.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

import '../models/bot.dart';
import "../utils/constants.dart";
import '../utils/custom_widget.dart';
import '../utils/utils.dart';
import '../utils/assistants_api.dart';

class CreateBot extends StatefulWidget {
  final User user;
  final Bots? bots;
  final Bot? bot;

  CreateBot({required this.user, this.bots, this.bot});

  @override
  CreateBotState createState() => CreateBotState();
}

class CreateBotState extends State<CreateBot> with RestorationMixin {
  final _nameController = TextEditingController();
  final _introController = TextEditingController();
  final _configInfoController = TextEditingController();
  final _functionController = TextEditingController();
  GlobalKey _functionformKey = GlobalKey<FormState>();
  var functionsBody = {};
  var fileSearchFiles = []; //files picked by user
  var codeInterpreterFiles = []; //files picked by user
  List vectoreStoreFiles = []; //Files in vectoreStore
  //code interpreter files in openai
  //key: fileName, value: fildID
  Map codeInterpreterFilesID = {};
  String? _assistant_id;
  bool _isUploading = false;
  bool _vsCreating = false;
  //key: vectorStoreId, value: vectorStore name
  Map _vectorStoreId = {};
  RestorableBool switchPublic = RestorableBool(true);
  RestorableBool switchFileSearch = RestorableBool(false);
  RestorableBool switchCodeInterpreter = RestorableBool(false);
  final dio = Dio();
  final assistant = AssistantsAPI();
  String? _fileName;
  List<int>? _fileBytes;
  String? _logoURL;
  double temperature = 1;
  GlobalKey _createBotformKey = GlobalKey<FormState>();

  @override
  String get restorationId => 'switch_demo';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(switchPublic, 'switch_value1');
    registerForRestoration(switchFileSearch, 'file_search');
    registerForRestoration(switchCodeInterpreter, 'code_interpreter');
  }

  @override
  void initState() {
    super.initState();
    if (widget.bot != null) {
      _logoURL = widget.bot!.avatar;
      _assistant_id = widget.bot!.assistant_id;
      _nameController.text = widget.bot!.name;
      _introController.text = widget.bot!.description ?? "";
      _configInfoController.text = widget.bot!.instructions ?? "";
      switchPublic = RestorableBool(widget.bot!.public ?? true);
      // TODO: add Model
      switchFileSearch = RestorableBool(widget.bot!.file_search ?? false);
      _vectorStoreId = widget.bot!.vector_store_ids ?? {};
      switchCodeInterpreter =
          RestorableBool(widget.bot!.code_interpreter ?? false);
      codeInterpreterFilesID = widget.bot!.code_interpreter_files ?? {};
      functionsBody = widget.bot!.functions ?? {};
      temperature = widget.bot!.temperature ?? 1.0;
    }
  }

  @override
  void dispose() {
    switchPublic.dispose();
    switchFileSearch.dispose();
    switchCodeInterpreter.dispose();
    fileSearchFiles.clear();
    functionsBody.clear();
    codeInterpreterFiles.clear();
    vectoreStoreFiles.clear();
    super.dispose();
  }

  Future<void> _pickLogo(context) async {
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
      setState(() {
        _fileBytes = result.files.first.bytes;
        _fileName = result.files.first.name;
      });
    }
  }

  Future<void> uploadLogo() async {
    if (_fileBytes != null) {
      var mt = DateTime.now().millisecondsSinceEpoch;
      String oss_name = "bot${widget.user.id}_${mt}" + _fileName!;
      var resp = await Client().putObject(
        _fileBytes!,
        "chat/avatar/" + oss_name,
      );
      _logoURL = (resp.statusCode == 200) ? resp.realUri.toString() : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var hpadding = isDisplayDesktop(context) ? 50.0 : 20.0;
    return Dialog(
        child: Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: hpadding),
      //margin: EdgeInsets.symmetric(vertical: 20, horizontal: 100),
      decoration: BoxDecoration(
          color: AppColors.chatPageBackground,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      child: Scaffold(
        backgroundColor: AppColors.chatPageBackground,
        appBar: AppBar(
          //shadowColor: Colors.red,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.chatPageBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(GalleryLocalizations.of(context)!.botCreateTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Form(
                key: _createBotformKey,
                child: Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: chooseLogo(context),
                        ),
                        Text('名称', style: TextStyle(fontSize: 15)),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: '输入智能体名字',
                                  hintStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (v) {
                                  return v == null || v.trim().isNotEmpty
                                      ? null
                                      : "名称不能为空";
                                })),
                        Text('简介', style: TextStyle(fontSize: 15)),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextFormField(
                              controller: _introController,
                              decoration: InputDecoration(
                                hintText: '用一句话介绍该智能体',
                                hintStyle: TextStyle(fontSize: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            )),
                        Text('配置信息', style: TextStyle(fontSize: 15)),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            child: TextFormField(
                              controller: _configInfoController,
                              decoration: InputDecoration(
                                hintText: '输入prompt',
                                hintStyle: TextStyle(fontSize: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              validator: (v) {
                                return v == null || v.trim().isNotEmpty
                                    ? null
                                    : "prompt不能为空";
                              },
                              maxLines: 5,
                            )),
                        Divider(),
                        Text(GalleryLocalizations.of(context)!.tools,
                            style: TextStyle(fontSize: 15)),
                        fileSearch(context),
                        if (_vsCreating)
                          ListTile(
                              dense: true, leading: CircularProgressIndicator())
                        else if (_vectorStoreId.isNotEmpty)
                          vectorstoreTab(context),
                        Divider(),
                        codeInterpreter(context),
                        if (codeInterpreterFilesID.isNotEmpty)
                          listCodeInterpreterFiles(context),
                        Divider(),
                        functions(context),
                        listFunctions(context),
                        Divider(),
                        Text("Temperature  ${temperature.toStringAsFixed(1)}",
                            style: TextStyle(fontSize: 15)),
                        temperatureSlide(context),
                        publicTo(context),
                        Divider(),
                      ],
                    ),
                  ),
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  child: Text(GalleryLocalizations.of(context)!.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(GalleryLocalizations.of(context)!.save),
                  onPressed: () async {
                    if (!(_createBotformKey.currentState as FormState)
                        .validate()) {
                      return;
                    }
                    await uploadLogo();
                    // assistant will create in backend
                    var resp = await saveToDB();
                    Navigator.of(context).pop();
                    if (resp == true)
                      notifyBox(
                          context: context, title: "success", content: "操作成功");
                    else
                      notifyBox(
                          context: context, title: "warning", content: "操作失败");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Future<bool> saveToDB() async {
    var _botsURL = botURL;
    try {
      if (widget.bot != null) _botsURL = botURL + "/${widget.bot!.id}";
      var botData = {
        "model": GPTModel.gptv40, //TODO: fix
        "name": _nameController.text,
        "assistant_id": _assistant_id,
        "avatar": _logoURL,
        "description": _introController.text,
        "instructions": _configInfoController.text,
        "author_id": widget.user.id,
        "author_name": widget.user.name,
        "public": switchPublic.value,
        "file_search": switchFileSearch.value,
        "code_interpreter": switchCodeInterpreter.value,
        "vector_store_ids": _vectorStoreId,
        "code_interpreter_files": codeInterpreterFilesID,
        "functions": functionsBody,
        "temperature": temperature,
      };
      Response resp = await dio.post(_botsURL, data: botData);
      if (resp.statusCode == 200) {
        if (widget.bot != null)
          widget.bots!.updateBot(resp.data, widget.bot!.id);
        else
          widget.bots!.addBot(resp.data);
        return true;
      }
    } catch (e) {
      debugPrint('saveToDB error: $e');
    }
    return false;
  }

  Widget vectorstoreTab(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.storage, size: 18),
      title: Text(_vectorStoreId.keys.first, style: TextStyle(fontSize: 14)),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline),
        tooltip: "删除Vector Store",
        onPressed: () async {
          await assistant.vectorStoreDelete(_vectorStoreId.keys.first);
          setState(() {
            _vectorStoreId = {};
          });
        },
      ),
      onTap: () async {
        _vectorStoreTaped();
      },
    );
  }

  void _vectorStoreTaped() async {
    vectoreStoreFiles = await assistant.getVectorStoreFiles(_vectorStoreId);
    String? action = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.chatPageBackground,
              title: Text("Vector Store: ${_vectorStoreId.keys.first}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  DataTable(
                      columns: [
                        DataColumn(label: Text("FILE")),
                        DataColumn(label: Text("UPLOADED")),
                        DataColumn(label: Text("")),
                      ],
                      rows: vectoreStoreFiles.map((vfile) {
                        return DataRow(cells: [
                          vectoreStoreFiles.isEmpty
                              ? DataCell(Text(""))
                              : DataCell(Text(vfile["id"])),
                          vectoreStoreFiles.isEmpty
                              ? DataCell(CircularProgressIndicator())
                              : DataCell(Text(vfile["created_at"].toString())),
                          DataCell(IconButton(
                            onPressed: !vectoreStoreFiles.isEmpty
                                ? () {
                                    setState(() {
                                      vectoreStoreFiles.removeWhere(
                                          (element) => element == vfile);
                                    });
                                    assistant.vectorStoreFileDelete(
                                        _vectorStoreId.keys.first, vfile["id"]);
                                  }
                                : null,
                            icon: Icon(Icons.delete_outline),
                          )),
                        ]);
                      }).toList()),
                  SizedBox(height: 20),
                  FilledButton.tonalIcon(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        var result = await _pickFile(context);
                        setState(() {
                          //fileSearchFiles.add(result);
                          _isUploading = true;
                        });
                        await assistant.uploadFile(result);
                        var newfile = await assistant.vectorStoreFile(
                            _vectorStoreId.keys.first, result.files.first.name);
                        setState(() {
                          vectoreStoreFiles.add(newfile);
                          _isUploading = false;
                        });
                      },
                      label: Text("Add"))
                ],
              ),
              actions: [
                FilledButton.tonalIcon(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () async {
                      //TODO: test
                      await assistant
                          .vectorStoreDelete(_vectorStoreId.keys.first);
                      _vectorStoreId = {};
                      Navigator.of(context).pop("delete");
                    },
                    label: Text("delete")),
                FilledButton.tonalIcon(
                    //icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop("close");
                    },
                    label: Text("Close"))
              ],
            );
          });
        });
    if (action != null && action == "delete") {
      _updateVs();
    }
  }

  void _updateVs() {
    setState(() {});
  }

  Widget fileSearch(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Switch(
          value: switchFileSearch.value,
          activeColor: Colors.blue[300],
          onChanged: (value) {
            setState(() {
              switchFileSearch.value = value;
            });
          },
        ),
        Container(
            margin: EdgeInsets.only(left: 10),
            child: Row(children: [
              Text(
                  textAlign: TextAlign.center,
                  GalleryLocalizations.of(context)!.fileSearch,
                  style: TextStyle(fontSize: 14)),
              if (isDisplayDesktop(context))
                IconButton(
                  onPressed: null,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.info_outline, size: 15),
                  tooltip: GalleryLocalizations.of(context)!.fileSearchTip,
                )
            ]))
      ]),
      FilledButton.tonalIcon(
          icon: Icon(Icons.add, size: 15),
          onPressed: switchFileSearch.value ? uploadFileSearchDialod : null,
          label: Text("Files", style: TextStyle(fontSize: 14)))
    ]);
  }

  void uploadFileSearchDialod() {
    _vectorStoreId.isEmpty ? uploadFileDialog() : _vectorStoreTaped();
  }

  void uploadFileDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.chatPageBackground,
              title: Text(GalleryLocalizations.of(context)!.fileSearchTitle),
              titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  DataTable(
                    showBottomBorder: true,
                    columns: [
                      DataColumn(label: Text("FILE")),
                      DataColumn(label: Text("SIZE")),
                      DataColumn(label: Text("UPLOADED")),
                      DataColumn(label: Text("")),
                    ],
                    rows: fileSearchFiles.map((pfile) {
                      //final file = File(path);
                      //print(pfile.files.first.size);
                      int currentIndex = fileSearchFiles.indexOf(pfile);
                      int lastIndex = fileSearchFiles.length - 1;
                      return DataRow(cells: [
                        DataCell(Text(pfile.files.first.name)),
                        currentIndex == lastIndex && _isUploading
                            ? DataCell(Text("-"))
                            : DataCell(Text("${pfile.files.first.size} Bytes")),
                        currentIndex == lastIndex && _isUploading
                            ? DataCell(CircularProgressIndicator())
                            : DataCell(Text(DateTime.now().toString())),
                        DataCell(IconButton(
                          onPressed: !_isUploading
                              ? () {
                                  setState(() {
                                    fileSearchFiles.removeWhere(
                                        (element) => element == pfile);
                                  });
                                }
                              : null,
                          icon: Icon(Icons.delete_outline),
                        )),
                      ]);
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  FilledButton.tonalIcon(
                      icon: Icon(Icons.add, size: 15),
                      onPressed: () async {
                        var result = await _pickFile(context);
                        setState(() {
                          fileSearchFiles.add(result);
                          _isUploading = true;
                        });
                        await assistant.uploadFile(result);
                        setState(() {
                          _isUploading = false;
                        });
                      },
                      label: Text("Add"))
                ],
              ),
              actions: [
                FilledButton.tonalIcon(
                    //icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      fileSearchFiles.clear();
                      _isUploading = false;
                    },
                    label: Text(GalleryLocalizations.of(context)!.cancel)),
                FilledButton.tonalIcon(
                    //icon: Icon(Icons.add),
                    onPressed: _onAttachPressed,
                    label: Text(GalleryLocalizations.of(context)!.save))
              ],
            );
          });
        });
  }

  /**
   * waiting create openai vectore store and
   * upload file to it, show CircularProgressIndicator
   * during the process
   */
  void _onAttachPressed() async {
    Navigator.of(context).pop();
    try {
      setState(() {
        _vsCreating = true;
      });
      var vid = await assistant.createVectorStore(fileSearchFiles);
      setState(() {
        _vectorStoreId[vid] = "vs name";
        _vsCreating = false;
      });
      print("vs_id:$_vectorStoreId");
      fileSearchFiles.clear();
    } finally {}
    _isUploading = false;
  }

  Widget codeInterpreter(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        children: [
          Switch(
            value: switchCodeInterpreter.value,
            activeColor: Colors.blue[300],
            onChanged: (value) {
              setState(() {
                switchCodeInterpreter.value = value;
              });
            },
          ),
          Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: Row(children: [
                Text(
                    textAlign: TextAlign.center,
                    GalleryLocalizations.of(context)!.codeInterpreter,
                    style: TextStyle(fontSize: 14)),
                if (isDisplayDesktop(context))
                  IconButton(
                    onPressed: null,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.info_outline, size: 15),
                    tooltip:
                        GalleryLocalizations.of(context)!.codeInterpreterTip,
                  )
              ]))
        ],
      ),
      FilledButton.tonalIcon(
          icon: Icon(Icons.add, size: 15),
          onPressed: switchCodeInterpreter.value
              ? uploadCodeInterpreterFileDialog
              : null,
          label: Text("Files", style: TextStyle(fontSize: 14)))
    ]);
  }

  Widget listCodeInterpreterFiles(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return Column(
        children: codeInterpreterFilesID.entries.map((entry) {
          return ListTile(
            enabled: false,
            dense: true,
            leading: Icon(Icons.file_present, size: 18),
            title: Text(entry.key),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline),
              tooltip: "删除文件",
              onPressed: !_isUploading
                  ? () async {
                      var res = await assistant.filedelete(entry.value);
                      setState(() {
                        if (res) codeInterpreterFilesID.remove(entry.key);
                      });
                    }
                  : null,
            ),
          );
        }).toList(),
      );
    });
  }

  void uploadCodeInterpreterFileDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.chatPageBackground,
              title:
                  Text(GalleryLocalizations.of(context)!.codeInterpreterTitle),
              titlePadding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  DataTable(
                    columns: [
                      DataColumn(label: Text("FILE")),
                      DataColumn(label: Text("SIZE")),
                      DataColumn(label: Text("UPLOADED")),
                      DataColumn(label: Text("")),
                    ],
                    rows: codeInterpreterFiles.map((pfile) {
                      //final file = File(path);
                      //print(pfile.files.first.size);
                      int currentIndex = codeInterpreterFiles.indexOf(pfile);
                      int lastIndex = codeInterpreterFiles.length - 1;
                      return DataRow(cells: [
                        DataCell(Text(pfile.files.first.name)),
                        currentIndex == lastIndex && _isUploading
                            ? DataCell(Text("-"))
                            : DataCell(Text("${pfile.files.first.size} Bytes")),
                        currentIndex == lastIndex && _isUploading
                            ? DataCell(CircularProgressIndicator())
                            : DataCell(Text(DateTime.now().toString())),
                        DataCell(IconButton(
                          onPressed: !_isUploading
                              ? () async {
                                  setState(() {
                                    codeInterpreterFiles.removeWhere(
                                        (element) => element == pfile);
                                  });
                                  if (codeInterpreterFilesID
                                      .containsKey(pfile.files.first.name)) {
                                    var res = await assistant.filedelete(
                                        codeInterpreterFilesID[
                                            pfile.files.first.name]);
                                    if (res)
                                      codeInterpreterFilesID
                                          .remove(pfile.files.first.name);
                                  }
                                }
                              : null,
                          icon: Icon(Icons.delete_outline),
                        )),
                      ]);
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  FilledButton.tonalIcon(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        var result = await _pickFile(context);
                        setState(() {
                          codeInterpreterFiles.add(result);
                          _isUploading = true;
                        });
                        await assistant.uploadFile(result);
                        setState(() {
                          _isUploading = false;
                        });
                        var fid =
                            await assistant.fileUpload(result.files.first.name);
                        if (fid.isNotEmpty) {
                          setState(() {
                            codeInterpreterFilesID[result.files.first.name] =
                                fid;
                          });
                        }
                      },
                      label: Text("Add"))
                ],
              ),
              actions: [
                FilledButton.tonalIcon(
                    //icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(
                        () {
                          codeInterpreterFiles.clear();
                        },
                      );
                    },
                    label: Text(GalleryLocalizations.of(context)!.cancel)),
                FilledButton.tonalIcon(
                    //icon: Icon(Icons.add),
                    onPressed: () {
                      //file has uploaded to server and openai
                      //there is nothing to do
                      Navigator.of(context).pop();
                      _clearUserSelectCPFiles();
                    },
                    label: Text(GalleryLocalizations.of(context)!.save))
              ],
            );
          });
        });
  }

  void _clearUserSelectCPFiles() {
    setState(() {
      codeInterpreterFiles.clear();
    });
  }

  Future _pickFile(context) async {
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
    }
    return result;
  }

  Widget functions(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(
          margin: EdgeInsets.only(right: 75),
          child: Row(children: [
            Text(GalleryLocalizations.of(context)!.functions,
                style: TextStyle(fontSize: 14)),
            if (isDisplayDesktop(context))
              IconButton(
                onPressed: null,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.info_outline, size: 15),
                tooltip: GalleryLocalizations.of(context)!.functionsTip,
              )
          ])),
      FilledButton.tonalIcon(
          icon: Icon(Icons.add, size: 15),
          onPressed: () {
            editFunction(context);
          },
          label: Text("Functions", style: TextStyle(fontSize: 14)))
    ]);
  }

  void editFunction(context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(GalleryLocalizations.of(context)!.functionsDialog),
              backgroundColor: AppColors.chatPageBackground,
              content: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(GalleryLocalizations.of(context)!.functionsDialogTip),
                  Divider(height: 40),
                  Expanded(
                      child: Container(
                          //margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Form(
                              key: _functionformKey,
                              child: TextFormField(
                                controller: _functionController,
                                decoration: InputDecoration(
                                  hintText: function_sample1,
                                  hintStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                validator: (v) {
                                  if ((v!.trim().isNotEmpty) &&
                                      isValidFunction(v)) return null;
                                  return "为空或格式错误";
                                },
                                maxLines: 21,
                              )))),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(GalleryLocalizations.of(context)!.cancel),
                  onPressed: () {
                    _functionController.clear();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(GalleryLocalizations.of(context)!.save),
                  onPressed: () {
                    if (!(_functionformKey.currentState as FormState)
                        .validate()) {
                      return;
                    }
                    setState(() {
                      var func = jsonDecode(_functionController.text);
                      functionsBody[func["name"]] = _functionController.text;
                    });
                    _functionController.clear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  bool isValidFunction(String str) {
    try {
      var func = jsonDecode(str);
      if (!func.containsKey("name")) return false;
      return true;
    } on FormatException {
      return false;
    }
  }

  Widget listFunctions(BuildContext context) {
    return Column(
      children: functionsBody.entries.map((entry) {
        var funcName = entry.key;
        var funcContent = entry.value;
        return ListTile(
          dense: true,
          leading: Icon(
            Icons.code,
            color: Colors.blue[300],
          ),
          title: Text(funcName.toString()),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outlined,
              size: 17,
            ),
            onPressed: () {
              setState(() {
                functionsBody.remove(funcName);
              });
            },
          ),
          onTap: () {
            _functionController.text = funcContent;
            editFunction(context);
          },
        );
      }).toList(),
    );
  }

  Widget temperatureSlide(BuildContext context) {
    return Container(
        margin: EdgeInsets.fromLTRB(0, 0, 15, 10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                min: 0,
                max: 2,
                value: temperature,
                onChanged: (value) {
                  setState(() {
                    temperature = value;
                  });
                },
              ),
              Container(
                  margin: EdgeInsets.fromLTRB(25, 0, 25, 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("稳定", style: TextStyle(fontSize: 12)),
                        Text("中立", style: TextStyle(fontSize: 12)),
                        Text("随机", style: TextStyle(fontSize: 12)),
                      ]))
            ]));
  }

  Widget publicTo(BuildContext context) {
    return Row(children: [
      Switch(
        value: switchPublic.value,
        activeColor: Colors.blue[300],
        onChanged: (value) {
          setState(() {
            switchPublic.value = value;
          });
        },
      ),
      Container(
          margin: EdgeInsets.only(left: 10, right: 75),
          child: Text('是否共享其他人使用?', style: TextStyle(fontSize: 14))),
    ]);
  }

  void loadDefaultImage() async {
    final ByteData data = await rootBundle.load('assets/images/bot/bot4.png');
    _fileBytes = data.buffer.asUint8List();
    _fileName = 'bot4.png';
  }

  Widget _displayLogo(BuildContext context) {
    var sz = 100.0;
    if (_fileBytes != null)
      return Image.memory(Uint8List.fromList(_fileBytes!),
          width: sz, height: sz, fit: BoxFit.cover);
    else if (_logoURL != null)
      return Image.network(_logoURL!, width: sz, height: sz, fit: BoxFit.cover);
    else {
      loadDefaultImage();
      return Image.asset('assets/images/bot/bot4.png',
          width: sz, height: sz, fit: BoxFit.cover);
    }
  }

  Widget chooseLogo(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Ink(
            child: InkWell(
          onTap: () {
            showCustomBottomSheet(context);
          },
          borderRadius: BorderRadius.circular(45.0),
          hoverColor: Colors.red.withOpacity(0.3),
          splashColor: Colors.red.withOpacity(0.5),
          child: _displayLogo(context),
        )));
  }

  Widget localImages(BuildContext context) {
    return ListBody(
      children: [
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            childAspectRatio: 1,
          ),
          itemCount: BotImages.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
                margin: EdgeInsets.all(5),
                child: InkWell(
                    onTap: () async {
                      final ByteData data = await rootBundle
                          .load('assets/images/bot/bot${index + 1}.png');
                      setState(() {
                        _fileBytes = data.buffer.asUint8List();
                        _fileName = 'bot${index + 1}.png';
                      });
                      Navigator.of(context).pop();
                    },
                    hoverColor: Colors.grey.withOpacity(0.3),
                    splashColor: Colors.brown.withOpacity(0.5),
                    child: Ink(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/bot/bot${index + 1}.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )));
          },
        ),
      ],
    );
  }

  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.upload),
                title: Text('上传本地图片'),
                onTap: () {
                  _pickLogo(context);
                  Navigator.pop(context);
                },
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('选择图片'),
                ),
              ),
              localImages(context),
            ],
          ),
        );
      },
    );
  }
}
