import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/vendor/assistants_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:flutter/material.dart';

class ChatfileMessage extends StatefulWidget {
  final Map<String, Attachment> files;
  final String? model;

  ChatfileMessage({
    Key? key,
    required this.files,
    this.model,
  });

  @override
  State createState() => ChatfileMessageState();
}

class ChatfileMessageState extends State<ChatfileMessage> {
  late final assistant;
  @override
  void initState() {
    super.initState();
    assistant = AssistantsAPI();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: attachmentView(context),
    );
  }

  Widget attachmentView(BuildContext context) {
    List<Map> _files = widget.files.entries.map((x) {
      return {
        "filename": x.key,
        "attachment": x.value,
      };
    }).toList();
    return CarouselView(
      itemExtent: isDisplayDesktop(context) ? 200 : 150,
      // backgroundColor: AppColors.chatPageBackground,
      onTap: (i) {
        handleDownload(_files[i]["filename"], _files[i]["attachment"]);
      },
      children: _files.map((x) {
        return attachedFileIcon(context, x["filename"], x["attachment"]);
      }).toList(),
    );
  }

  Widget attachedFileIcon(
      BuildContext context, String attachedFileName, Attachment attachFile) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        // color: AppColors.inputBoxBackground,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        title: Text(attachedFileName, overflow: TextOverflow.ellipsis),
        leading: Icon(Icons.description_outlined, color: Colors.pink[300]),
        // onTap: () {
        //   handleDownload(attachedFileName, attachFile);
        // },
        trailing: (attachFile.downloading!
            ? CircularProgressIndicator(strokeWidth: 2)
            : Icon(Icons.download_for_offline_outlined)),
      ),
    );
  }

  Future<void> handleDownload(
      String attachedFileName, Attachment attachFile) async {
    setState(() {
      attachFile.downloading = true;
    });
    var res = 'can not download';
    if (Models.checkORG(widget.model!, Organization.openai))
      res = await assistant.downloadFile(attachFile.file_id!, attachedFileName);
    setState(() {
      attachFile.downloading = false;
    });

    showMessage(context, res);
  }
  // Widget attachmentList(BuildContext context, attachments) {
  //   final width = MediaQuery.of(context).size.width;
  //   final int crossAxisCount = (width ~/ 300).clamp(1, 3);
  //   final double childAspectRatio = (width / crossAxisCount) / 80.0;
  //   final hpaddng = isDisplayDesktop(context) ? 15.0 : 15.0;
  //   return GridView.builder(
  //     key: UniqueKey(),
  //     controller: _attachmentscroll,
  //     shrinkWrap: true,
  //     padding: EdgeInsets.symmetric(horizontal: hpaddng, vertical: 5),
  //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //       mainAxisSpacing: 10.0,
  //       crossAxisSpacing: 20.0,
  //       childAspectRatio: childAspectRatio,
  //       crossAxisCount: crossAxisCount,
  //     ),
  //     itemCount: attachments.entries.length,
  //     itemBuilder: (BuildContext context, int index) {
  //       MapEntry entry = attachments.entries.elementAt(index);
  //       return attachedFileIcon(context, entry.key, entry.value);
  //     },
  //   );
  // }
}
