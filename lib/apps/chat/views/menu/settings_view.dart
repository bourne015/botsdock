import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'package:botsdock/apps/chat/utils/constants.dart';

class SettingsView extends StatefulWidget {
  final User user;
  const SettingsView({super.key, required this.user});

  @override
  State<SettingsView> createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> with RestorationMixin {
  double temperature = 1;
  RestorableBool internet = RestorableBool(false);
  RestorableBool artifact = RestorableBool(false);
  ThemeMode theme = ThemeMode.system;

  @override
  String get restorationId => 'switch_demo';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(internet, 'model internet function');
    registerForRestoration(artifact, 'model artifact function');
  }

  @override
  void initState() {
    artifact = RestorableBool(widget.user.settings?.artifact ?? false);
    internet = RestorableBool(widget.user.settings?.internet ?? false);
    temperature = widget.user.settings?.temperature ?? 1.0;
    theme = widget.user.settings?.themeMode ?? ThemeMode.system;
    super.initState();
  }

  @override
  void dispose() {
    if (widget.user.isLogedin)
      ChatAPI().updateUser(
          widget.user.id, {"settings": widget.user.settings!.toJson()});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BORDERRADIUS15,
        child: Container(
          width: 400,
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
              Tab(icon: Icon(Icons.settings)),
              Tab(icon: Icon(Icons.description_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: settingItems(context),
            ),
            SingleChildScrollView(
                child: Container(
              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              alignment: Alignment.topCenter,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: modelDesc(context),
            )),
          ],
        ));
  }

  Widget settingItems(BuildContext context) {
    return Column(
      children: [
        functionSwitch(
          context,
          artifact,
          name: "可视化",
          desc: "生成图表、动画、流程图、网页预览等可视化能",
          onChange: (v) {
            widget.user.settings?.artifact = v;
          },
        ),
        Divider(),
        functionSwitch(
          context,
          internet,
          name: "联网",
          desc: "获取Google搜索的数据",
          onChange: (v) {
            widget.user.settings?.internet = v;
          },
        ),
        Divider(),
        ListTile(
          leading: Text(
            "Temperature",
            // style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          title: temperatureSlide(context),
          subtitle: Text(
            "值越大模型思维越发散",
            textAlign: TextAlign.center,
            // style: TextStyle(fontSize: 10.5, color: AppColors.subTitle),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          trailing: Text(
            "${temperature.toStringAsFixed(2)}",
            // style: TextStyle(fontSize: 12.5),
          ),
        ),
        Divider(),
        Container(
          margin: EdgeInsets.only(top: 10),
          child: ThemeSetting(context),
        ),
      ],
    );
  }

  Widget functionSwitch(
    BuildContext context,
    RestorableBool v, {
    required void Function(bool) onChange,
    String? name,
    String? desc,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        name ?? "",
        style: Theme.of(context).textTheme.titleSmall,
      ),
      // title: null,
      subtitle: Text(
        desc ?? "",
        // style: TextStyle(fontSize: 10.5, color: AppColors.subTitle),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      trailing: Transform.scale(
        scale: 0.7,
        child: Switch(
          value: v.value,
          activeColor: Colors.blue[300],
          onChanged: (value) {
            setState(() {
              v.value = value;
              onChange(value);
            });
          },
        ),
      ),
    );
  }

  Widget temperatureSlide(BuildContext context) {
    return Container(
        // margin: EdgeInsets.fromLTRB(0, 0, 15, 10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Container(
          //     margin: EdgeInsets.fromLTRB(45, 0, 45, 0),
          //     child: Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text("稳定", style: TextStyle(fontSize: 10.5)),
          //           Text("随机", style: TextStyle(fontSize: 10.5)),
          //         ])),
          Transform.scale(
            scale: 0.7,
            child: Slider(
              min: -0.1,
              max: 2,
              divisions: 100,
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              value: temperature,
              onChanged: (value) {
                setState(() {
                  temperature = value;
                });
              },
              onChangeEnd: (value) {
                widget.user.settings?.temperature = value;
              },
            ),
          ),
        ]));
  }

  Widget ThemeSetting(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: <ButtonSegment<ThemeMode>>[
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          label: Text(
            '浅色',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          label: Text(
            '深色',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          icon: Icon(Icons.dark_mode_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          label: Text(
            '跟随系统',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          icon: Icon(Icons.computer_outlined),
        ),
      ],
      selected: <ThemeMode>{theme},
      onSelectionChanged: (Set<ThemeMode> newSelection) {
        setState(() {
          // By default there is only a single segment that can be
          // selected at one time, so its value is always the first
          // item in the selected set.
          theme = newSelection.first;
          widget.user.themeMode = theme;
        });
      },
    );
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
                // color: Colors.white,
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
