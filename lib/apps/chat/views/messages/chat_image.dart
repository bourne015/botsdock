import 'package:botsdock/apps/chat/models/data.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/constants.dart';
import 'package:flutter/material.dart';

class ChatImageMessage extends StatefulWidget {
  final Map<String, VisionFile> images;

  ChatImageMessage({
    Key? key,
    required this.images,
  });

  @override
  State createState() => ChatImageMessageState();
}

class ChatImageMessageState extends State<ChatImageMessage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isDisplayDesktop(context) ? 250 : 150,
      child: imageView(context),
    );
  }

  Widget imageView(BuildContext context) {
    List<Map> _imgs = widget.images.entries.map((x) {
      return {
        "filename": x.key,
        "imageUrl": x.value.url,
        "imageBytes": x.value.bytes,
      };
    }).toList();
    return CarouselView(
      itemExtent: isDisplayDesktop(context) ? 300 : 150,
      // backgroundColor: AppColors.userMsgBox,
      onTap: (i) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  loadImage(
                    context,
                    filename: _imgs[i]["filename"],
                    imageurl: _imgs[i]["imageUrl"],
                    imagebytes: _imgs[i]["imagebytes"],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      // color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    child: TextButton.icon(
                      label: Text(
                        "下载",
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        downloadImage(
                          fileUrl: _imgs[i]["imageUrl"],
                          imageData: _imgs[i]["imagebytes"],
                        );
                      },
                      icon: Icon(Icons.download, size: 26),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      children: _imgs.map((x) {
        return loadImage(context,
            filename: x["filename"],
            imageurl: x["imageUrl"],
            imagebytes: x["imageBytes"],
            height: 250.0,
            width: 200.0);
        // return contentImage(
        //   context,
        //   filename: x["filename"],
        //   imageUrl: x["imageUrl"],
        //   imageBytes: x["imageBytes"],
        // );
      }).toList(),
    );
  }

  Widget loadImage(BuildContext context,
      {filename, imageurl, imagebytes, height, width}) {
    if (imageurl != null && imageurl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        clipBehavior: Clip.hardEdge,
        child: FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          image: NetworkImage(imageurl),
          fit: BoxFit.fitWidth,
          height: height,
          width: width,
          fadeInDuration: const Duration(milliseconds: 10),
          imageErrorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image_outlined),
        ),
      );
    } else if (imagebytes != null && imagebytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          height: height,
          width: width,
          image: MemoryImage(imagebytes),
          fadeOutDuration: const Duration(milliseconds: 10),
          imageErrorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image),
        ),
      );
    } else
      return Text("load image failed");
  }
  // Widget visionFilesList(BuildContext context, visionFiles) {
  //   final width = MediaQuery.of(context).size.width;
  //   final int crossAxisCount = (width ~/ 300).clamp(1, 3);
  //   final double childAspectRatio = (width / crossAxisCount) / 400.0;
  //   final hpaddng = isDisplayDesktop(context) ? 15.0 : 15.0;
  //   return GridView.builder(
  //     key: UniqueKey(),
  //     controller: _visionFilescroll,
  //     shrinkWrap: true,
  //     padding: EdgeInsets.symmetric(horizontal: hpaddng, vertical: 5),
  //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //       mainAxisSpacing: 10.0,
  //       crossAxisSpacing: 20.0,
  //       childAspectRatio: childAspectRatio,
  //       crossAxisCount: crossAxisCount,
  //     ),
  //     itemCount: visionFiles.entries.length,
  //     itemBuilder: (BuildContext context, int index) {
  //       MapEntry entry = visionFiles.entries.elementAt(index);
  //       return contentImage(
  //         context,
  //         filename: entry.key,
  //         imageUrl: entry.value.url,
  //         imageBytes: entry.value.bytes,
  //       );
  //     },
  //   );
  // }

  Widget contentImage(BuildContext context, {filename, imageUrl, imageBytes}) {
    return GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    child: loadImage(
                  context,
                  filename: filename,
                  imageurl: imageUrl,
                  imagebytes: imageBytes,
                ));
              });
        },
        onLongPressStart: (details) {
          _showDownloadMenu(context, details.globalPosition,
              filename: filename, imageUrl: imageUrl, imageBytes: imageBytes);
        },
        child: loadImage(context,
            filename: filename,
            imageurl: imageUrl,
            imagebytes: imageBytes,
            height: 250.0,
            width: 200.0));
  }

  void _showDownloadMenu(BuildContext context, Offset position,
      {filename, imageUrl, imageBytes}) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx, // Left
      position.dy, // Top
      overlay!.size.width - position.dx, // Right
      overlay.size.height - position.dy, // Bottom
    );

    showMenu(
      context: context,
      position: positionRect,
      items: <PopupMenuEntry>[
        const PopupMenuItem(
          value: 'download',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text("download"),
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text("share"),
          ),
        ),
      ],
    ).then((selectedValue) async {
      if (selectedValue == 'download') {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          downloadImage(fileUrl: imageUrl);
        } else if (imageBytes != null && imageBytes.isNotEmpty) {
          downloadImage(imageData: imageBytes);
        }
      }
    });
  }
}
