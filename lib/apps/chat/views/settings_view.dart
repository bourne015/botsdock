import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BORDERRADIUS15,
        child: Container(
          width: 500,
          child: DefaultTabController(
            initialIndex: 0,
            length: 2,
            child: settingPannel(context),
          ),
        ));
  }

  Widget settingPannel(BuildContext context) {
    String title = "Settings";
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.description_outlined)),
              Tab(icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            SingleChildScrollView(
                child: Container(
              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              alignment: Alignment.topCenter,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: modelDesc(context),
            )),
            SingleChildScrollView(child: Text("todo")),
          ],
        ));
  }

  Widget modelDesc(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _marddownSimple("## 模型数据"),
            SizedBox(height: 10),
            DataTable(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue),
                borderRadius: BORDERRADIUS10,
              ),
              horizontalMargin: 5,
              columnSpacing: 15,
              columns: [
                DataColumn(label: Text('模型')),
                DataColumn(
                    label: Text(
                        GalleryLocalizations.of(context)!.contextWindow +
                            "\n(tokens)",
                        textAlign: TextAlign.center)),
                DataColumn(
                    label: Text(
                        GalleryLocalizations.of(context)!.price + "\n每百万Token",
                        textAlign: TextAlign.center)),
                DataColumn(label: Text("综合评分"))
              ],
              rows: [
                DataRow(selected: true, cells: [
                  DataCell(Text('GPT-4o mini')),
                  DataCell(Text('128K')),
                  DataCell(Text('输入: \$0.15\n输出: \$0.60')),
                  DataCell(Text("41.26")),
                ]),
                DataRow(cells: [
                  DataCell(Text('GPT-4o')),
                  DataCell(Text('128K')),
                  DataCell(Text('输入: \$2.50\n输出: \$10.00')),
                  DataCell(Text("55.33")),
                ]),
                DataRow(cells: [
                  DataCell(Text('o1 mini')),
                  DataCell(Text('128K')),
                  DataCell(Text('输入: \$1.10\n输出: \$4.40')),
                  DataCell(Text("57.76")),
                ]),
                DataRow(cells: [
                  DataCell(Text('DALL·E')),
                  DataCell(Text('-')),
                  DataCell(Text('\$0.04/image')),
                  DataCell(Text("-")),
                ]),
                DataRow(selected: true, cells: [
                  DataCell(Text('Claude 3.5 Haiku')),
                  DataCell(Text('200K')),
                  DataCell(Text('输入: \$0.80\n输出: \$4.00')),
                  DataCell(Text("43.45")),
                ]),
                DataRow(cells: [
                  DataCell(Text('Claude 3.5 Sonnet')),
                  DataCell(Text('200K')),
                  DataCell(Text('输入: \$3.00\n输出: \$15.00')),
                  DataCell(Text("59.03")),
                ]),
                DataRow(cells: [
                  DataCell(Text('Claude 3.7 Sonnet')),
                  DataCell(Text('200K')),
                  DataCell(Text('输入: \$3.00\n输出: \$15.00')),
                  DataCell(_marddownSimple("65.56" + ":rocket:")),
                ]),
                DataRow(cells: [
                  DataCell(Text('Claude 3 Opus')),
                  DataCell(Text('200K')),
                  DataCell(Text('输入: \$15.00\n输出: \$75.00')),
                  DataCell(Text("49.16")),
                ]),
                DataRow(selected: true, cells: [
                  DataCell(Text('Gemini 1.5 Pro')),
                  DataCell(Text('2M')),
                  DataCell(Text('输入: \$0.15\n输出: \$0.60')),
                  DataCell(Text("54.33")),
                ]),
                DataRow(cells: [
                  DataCell(Text('Gemini 2.0 Flash')),
                  DataCell(Text('1M')),
                  DataCell(Text('输入: \$0.10\n输出: \$0.40')),
                  DataCell(_marddownSimple("61.47" + ":rocket:")),
                ]),
                DataRow(selected: true, cells: [
                  DataCell(Text('DeepSeek V3')),
                  DataCell(Text('64K')),
                  DataCell(Text('输入: \$0.27\n输出: \$1.10')),
                  DataCell(Text("60.45")),
                ]),
                DataRow(cells: [
                  DataCell(Text('DeepSeek R1')),
                  DataCell(Text('64K')),
                  DataCell(Text('输入: \$0.55\n输出: \$2.19')),
                  DataCell(_marddownSimple("71.57" + ":rocket:")),
                ]),
              ],
            ),
            _marddownSimple("评分数据来源于：[LiveBench](https://livebench.ai/#/)"),
          ],
        ));
  }

  MarkdownBody _marddownSimple(String text) {
    return MarkdownBody(
      data: text,
      onTapLink: (text, href, title) => launchUrl(Uri.parse(href!)),
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        <md.InlineSyntax>[
          md.EmojiSyntax(),
        ],
      ),
    );
  }
}
