import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:botsdock/apps/chat/views/messages/common.dart';
import 'package:botsdock/apps/chat/views/messages/webveiw.dart';
import 'package:flutter/material.dart';

class ChatArtifactMessage extends StatefulWidget {
  final dynamic function;

  ChatArtifactMessage({
    Key? key,
    required this.function,
  });

  @override
  State createState() => ChatArtifactMessageState();
}

class ChatArtifactMessageState extends State<ChatArtifactMessage> {
  double artifactWidth = Artifact_MIN_W;
  double artifactHight = Artifact_MIN_H;

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
    if (widget.function["type"] == null) {
      Logger.warn(
          "Artifact err: ct: ${widget.function["content"]}, type:${widget.function["type"]}");
      return contentMarkdown(context, widget.function["content"] ?? "");
    }
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      width: artifactWidth + 10,
      height: artifactHight + 50,
      decoration: BoxDecoration(
          // color: Colors.red,
          // border: Border.all(color: ),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Text(
                  widget.function["artifactName"].length > 25
                      ? widget.function["artifactName"].substring(0, 25)
                      : widget.function["artifactName"],
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: "最小化",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        artifactWidth = Artifact_MIN_W;
                        artifactHight = 5;
                      });
                    },
                    icon: Icon(Icons.minimize),
                  ),
                  IconButton(
                    tooltip: "恢复",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        artifactWidth = Artifact_MIN_W;
                        artifactHight = Artifact_MIN_H;
                      });
                    },
                    icon: Icon(Icons.refresh, size: 18),
                  ),
                  IconButton(
                    tooltip: "最大化",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        artifactWidth = Artifact_MAX_W;
                        artifactHight = Artifact_MAX_H;
                      });
                    },
                    icon: Icon(Icons.maximize, size: 18),
                  ),
                ],
              ),
            ],
          ),
          HtmlContentWidget(
            width: artifactWidth,
            height: artifactHight,
            content: widget.function["content"] ?? "",
            contentType: widget.function["type"].toLowerCase(),
          )
        ],
      ),
    );
  }
}
