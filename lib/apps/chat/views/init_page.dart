import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/apps/chat/utils/prompts.dart';
import 'package:botsdock/apps/chat/views/spirit_cat.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';

import '../models/pages.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/custom_widget.dart';
import '../utils/utils.dart';

class InitPage extends StatefulWidget {
  const InitPage({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => InitPageState();
}

class InitPageState extends State<InitPage> {
  String? selectedORG;
  final ChatAPI chats = ChatAPI();

  Map<Organization, List<PopupMenuEntry<AIModel>>> modelItems = {
    Organization.openai: [],
    Organization.anthropic: [],
    Organization.google: [],
    Organization.deepseek: [],
  };

  @override
  void initState() {
    super.initState();
  }

  void _initializeMenuItems() {
    modelItems = {
      for (var org in Organization.values)
        org: Models.getOrganizationModels(org)
            .map((x) => _PopupMenuModelItem(
                  value: x,
                  price: x.price,
                  modelName: x.name,
                ))
            .toList()
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Property property = Provider.of<Property>(context);
    final currentOrg = Models.getOrgByModelId(property.initModelVersion)!;
    selectedORG = getOrgInfo(currentOrg).name;
    _initializeMenuItems();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            modelSelectButton(context),
            Align(
              alignment: Alignment.center,
              child:
                  Text("Chat", style: Theme.of(context).textTheme.displayLarge),
            ),
            if (isDisplayDesktop(context) && constraints.maxHeight > 350)
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      if (isDisplayDesktop(context) ||
                          constraints.maxHeight > 700)
                        CustomCard(
                          icon: Icons.pets,
                          color: const Color.fromARGB(255, 227, 84, 132),
                          title: "使用说明",
                          prompt: "describe",
                        ),
                      if (isDisplayDesktop(context) ||
                          constraints.maxHeight > 700)
                        CustomCard(
                          icon: Icons.translate_outlined,
                          color: const Color.fromARGB(255, 104, 197, 107),
                          title: "翻译员",
                          prompt: Prompt.translator,
                        ),
                      CustomCard(
                        icon: Icons.computer_sharp,
                        color: const Color.fromARGB(255, 241, 227, 104),
                        title: "精通计算机知识的程序员",
                        prompt: Prompt.programer,
                      ),
                      CustomCard(
                        icon: Icons.more_outlined,
                        color: Color.fromARGB(255, 119, 181, 232),
                        title: "五一去成都旅游的攻略",
                        prompt: Prompt.tguide,
                      ),
                    ],
                  )),
            Container(),
          ]);
    });
  }

  Widget modelSelectButton(BuildContext context) {
    Property property = Provider.of<Property>(context);
    return Stack(alignment: Alignment.topCenter, children: [
      Container(
          margin: EdgeInsets.only(top: 32),
          child: CustomSlidingSegmentedControl(
            initialValue: selectedORG,
            children: _buildModelSegments(context),
            decoration: BoxDecoration(
              borderRadius: BORDERRADIUS10,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            thumbDecoration: BoxDecoration(
              //color: Colors.white,
              borderRadius: BORDERRADIUS10,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .3),
                  blurRadius: 4.0,
                  spreadRadius: 1.0,
                  offset: Offset(0.0, 2.0),
                )
              ],
            ),
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
            onValueChanged: (orgName) {
              _handleOrgChange(orgName, property);
            },
          )),
      SpiritCat(),
    ]);
  }

  Map<String, Widget> _buildModelSegments(BuildContext context) {
    return Map.fromEntries(Organization.values.map((org) {
      final _orginfo = getOrgInfo(org);
      return MapEntry(
          _orginfo.name,
          ModelSegment(
            selected: selectedORG == _orginfo.name,
            logo: _orginfo.logo,
            color: _orginfo.color,
            name: _orginfo.name,
            dropdownMenu: selectedORG == _orginfo.name
                ? _DropdownMenu(
                    context: context,
                    organization: org,
                    currentValue: currentModels[org]!,
                    onSelected: (value) {
                      setState(() {
                        currentModels[org] = value;
                      });
                    })
                : null,
          ));
    }));
  }

  Widget _DropdownMenu({
    required BuildContext context,
    required Organization organization,
    required AIModel currentValue,
    required Function(AIModel) onSelected,
  }) {
    Property property = Provider.of<Property>(context);

    return PopupMenuButton<AIModel>(
      initialValue: currentValue,
      tooltip: GalleryLocalizations.of(context)!.selectModelTooltip,
      shadowColor: Colors.blue,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BORDERRADIUS10,
      ),
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.modelSelectorBackground,
        child: Text(
          currentValue.abbrev,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      padding: const EdgeInsets.only(left: 2),
      onSelected: (AIModel value) {
        property.initModelVersion = value.id;
        onSelected(value);
      },
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) => modelItems[organization]!,
    );
  }

  void _handleOrgChange(String orgName, Property property) {
    final org = Organization.values
        .firstWhere((o) => o.name.toLowerCase() == orgName.toLowerCase());
    final currentORGModel = currentModels[org]!;

    setState(() {
      property.initModelVersion = currentORGModel.id;
      selectedORG = orgName;
      Global.saveProperties(model: currentORGModel.id);
    });
  }

  Widget inputTypeIcon(Map<String, double> price, bool selected) {
    String _inputPrice = price["input"]!.toStringAsFixed(2);
    String _outputPrice = price["output"]!.toStringAsFixed(2);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(
          color: selected ? Colors.tealAccent[400]! : Colors.yellowAccent,
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.transparent, // 使用渐变背景
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (price["input"] != 0)
                Text("\$$_inputPrice",
                    style: TextStyle(fontSize: 6.0, color: Colors.white)),
              if (price["output"] != 0)
                Text("\$$_outputPrice",
                    style: TextStyle(fontSize: 6.0, color: Colors.white)),
              if (price["input"] == 0 && price["output"] == 0)
                Text("free",
                    style: TextStyle(fontSize: 7.5, color: Colors.white)),
            ],
          )
          // Text(
          //   inputs,
          //   style: TextStyle(
          //     fontSize: 7,
          //     fontWeight: FontWeight.w400,
          //     color: Colors.white,
          //     shadows: [
          //       Shadow(
          //         color: Colors.black.withValues(alpha: 0.2),
          //         blurRadius: 2,
          //         offset: const Offset(1, 1),
          //       )
          //     ],
          //   ),
          // ),
          ),
    );
  }

  PopupMenuItem<AIModel> _PopupMenuModelItem({
    required AIModel value,
    required Map<String, double> price,
    required String modelName,
  }) {
    bool isSelected = currentModels[value.organization] == value;

    return PopupMenuItem<AIModel>(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      value: value,
      child: Material(
        //color: Colors.transparent,
        // color: AppColors.drawerBackground,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BORDERRADIUS15,
          ),
          child: InkWell(
            borderRadius: BORDERRADIUS15,
            onTap: () {
              Global.saveProperties(model: value.id);
              Navigator.pop(context, value);
            },
            //onHover: (hovering) {},
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 5),
              leading: inputTypeIcon(price, isSelected),
              title: Text(modelName, overflow: TextOverflow.ellipsis),
              subtitle: Container(
                  width: 150,
                  child: LinearPercentIndicator(
                    width: 150,
                    lineHeight: 12,
                    padding: EdgeInsets.all(0),
                    animation: true,
                    animationDuration: 1000,
                    barRadius: Radius.circular(5.0),
                    percent: value.score / 100,
                    center: Text(
                      value.score > 0 ? "score ${value.score}" : "",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 8.5,
                        color: Colors.grey,
                      ),
                    ),
                    progressColor:
                        isSelected ? Colors.tealAccent[400] : Colors.teal[50],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class ModelSegment extends StatelessWidget {
  final bool selected;
  final String logo;
  final Color? color;
  final String name;
  final Widget? dropdownMenu;

  const ModelSegment({
    required this.selected,
    required this.logo,
    required this.color,
    required this.name,
    required this.dropdownMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Tooltip(
        message: selected ? "" : name,
        child: Image.asset(
          logo,
          height: 24,
          width: 24,
          color: selected ? color : Colors.grey,
        ),
      ),
      if (selected)
        Container(
          width: 65,
          child: Text(' $name', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      if (selected && dropdownMenu != null) dropdownMenu!,
    ]);
  }
}

class CustomCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String prompt;
  final ChatAPI chats = ChatAPI();

  CustomCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.prompt});

  @override
  Widget build(BuildContext context) {
    User user = Provider.of<User>(context, listen: false);
    Pages pages = Provider.of<Pages>(context, listen: false);
    Property property = Provider.of<Property>(context, listen: false);
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              onTap: () {
                if (title == "使用说明")
                  describe(
                    context: context,
                    title: title,
                  );
                else if (user.isLogedin)
                  chats.newTextChat(pages, property, user, prompt);
                else
                  showMessage(context, "请登录");
              },
              child: Container(
                  width: 150,
                  height: 100,
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Align(
                          alignment: Alignment.topLeft,
                          child: Icon(
                            icon,
                            size: 20.0,
                            color: color,
                          )),
                      SizedBox(height: 8),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Text(title, style: TextStyle(fontSize: 15)))
                    ],
                  ))),
        ));
  }

  void describe({context, var title}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        // backgroundColor: AppColors.chatPageBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: ClipRRect(
          borderRadius: BORDERRADIUS15,
          child: Container(
            width: 500,
            margin: EdgeInsets.fromLTRB(35, 30, 0, 0),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: _describe,
                // styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                styleSheet: MarkdownStyleSheet(
                  tableColumnWidth: FixedColumnWidth(150),
                  tablePadding: EdgeInsets.symmetric(horizontal: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _describe = """
### 1.输入格式

##### GPT
  - [x] 文本
  - [x] 图片: JPEG, PNG, GIF, WEBP
  - [x] 文档, 支持常用文档格式(PDF, DOC, PPT, TXT...), 功能待完善

##### Claude
  - [x] 文本
  - [x] 图片
  - [x] 文档, 仅支持PDF

##### Gemini
  - [x] 文本
  - [x] 图片
  - [x] 文档: PDF、文本文档(py, js, txt, html, css, md, csv,xml, rtf)

##### DeepSeek
  - [x] 文本
  - [ ] 图片
  - [ ] 文档

### 2.可视化
- 可视化功能支持生成**流程图**、**甘特图**、**时序图**、**思维导图**、**网页**等；
- Gemini不支持可视化输出

### 3.文档生成
- 仅GPT系列模型支持生成文档, 有两种方式:
- **方式1**: 新建智能体中开启'代码解释器(Code Interpreter)'后即支持生成文档，'Data Analyst'智能体已开启code Interpreter
- **方式2**: 新会话选择GPT模型并添加附件文档后, 会自动开启Code Interpreter和File Search功能

### 4.temperature设置
- Claude系列模型的范围是: [0.0, 1.0], 其余模型范围: [0.0, 2.0]
- 较低的值(例如0.2)将使其更加集中和确定, 适合对于分析/解题/多项选择
- 较高的值(如1.5)将使输出更加随机,适合对于创造性和生成性任务
- 如不确定怎么设置,可将值设置到最小(-0.1), 此时后端将缺省设置, 模型端会使用默认值

| 场景 | temperature |
| --- | --- |
| 代码生成/数学解题| 0.1 |
| 数据分析 |  1.0|
| 通用对话 |  1.3|
| 翻译| 1.3 |
| 创意类写作| 1.5 |

### 5.tips
- 手机端, 在浏览器中将页面添加到主屏幕, 可将网站作为PWA应用
""";
