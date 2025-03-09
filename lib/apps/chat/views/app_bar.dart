import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/utils.dart';
import '../utils/constants.dart';
import '../models/pages.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MyAppBar({Key? key}) : super(key: key);
  @override
  State<MyAppBar> createState() => MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}

class MyAppBarState extends State<MyAppBar> with RestorationMixin {
  double temperature = 1;
  RestorableBool switchArtifact = RestorableBool(true);
  RestorableBool switchInternet = RestorableBool(true);

  @override
  String get restorationId => 'switch_test';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(switchArtifact, 'switch_artifact');
    registerForRestoration(switchInternet, 'switch_internet');
  }

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
    Property property = Provider.of<Property>(context);
    Pages pages = Provider.of<Pages>(context);
    User user = Provider.of<User>(context);
    if (property.onInitPage) {
      switchArtifact.value = user.settings?.artifact ?? false;
      switchInternet.value = user.settings?.internet ?? false;
      temperature = user.settings?.temperature ?? 1.0;
    } else {
      switchArtifact.value = pages.currentPage!.artifact;
      switchInternet.value = pages.currentPage!.internet;
      temperature = pages.currentPage!.temperature ?? 1.0;
    }
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      AppBar(
        leading: !isDisplayDesktop(context)
            ? appbarLeading(context, property)
            : null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appbarTitle(context),
            SizedBox(width: 10),
            ...appbarIcons(pages, property),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 44,
        centerTitle: true,
        actions: [
          if (!property.onInitPage &&
              pages.currentPage?.model != DeepSeekModel.dc_r)
            _appBarMenu(context),
        ],
      ),
      // Divider(
      //   height: 1.0,
      //   thickness: 1.0,
      //   color: AppColors.drawerDivider,
      // ),
    ]);
  }

  List<Widget> appbarIcons(Pages pages, Property property) {
    var res = [
      Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: Icon(null, color: Colors.blue[700])),
      Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: Icon(null, color: Colors.blue[700])),
    ];
    if (!property.onInitPage) {
      if (pages.currentPage!.artifact && pages.currentPage!.internet)
        res = [
          Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.bar_chart, color: Colors.blue[400])),
          Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.language, color: Colors.blue[400])),
        ];
      else if (pages.currentPage!.artifact)
        res[0] = Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.bar_chart, color: Colors.blue[400]));
      else if (pages.currentPage!.internet)
        res[0] = Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.language, color: Colors.blue[400]));
    }
    return res;
  }

  Widget _appBarMenu(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    User user = Provider.of<User>(context, listen: false);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded),
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      position: PopupMenuPosition.under,
      padding: const EdgeInsets.only(left: 2),
      shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS10),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(
          context,
          "clear",
          icon: Icon(Icons.delete_outline),
          title: "清空当前页面",
          onTap: () {
            Navigator.of(context).pop();
            pages.clearCurrentPage();
            ChatAPI().saveChats(user, pages, pages.currentPageID);
          },
        ),
        PopupMenuDivider(),
        _buildArtifactSwitch(context),
        PopupMenuDivider(),
        _buildInternetSwitch(context),
        PopupMenuDivider(),
        _buildtemperatureSlide(context),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(BuildContext context, String value,
      {Icon? icon, String? title, void Function()? onTap}) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.all(0),
      value: value,
      child: Material(
        // color: AppColors.drawerBackground,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(borderRadius: BORDERRADIUS15),
            child: InkWell(
              borderRadius: BORDERRADIUS15,
              onTap: onTap,
              child: ListTile(
                contentPadding: EdgeInsets.only(left: 5),
                leading: icon,
                title: Text(
                  title ?? "",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            )),
      ),
    );
  }

  Widget appbarTitle(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Text(
      pages.currentPageID > -1 ? pages.currentPage!.model : "",
      // style: const TextStyle(fontSize: 16, color: AppColors.appBarText),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget appbarLeading(BuildContext context, Property property) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        if (isDisplayDesktop(context)) {
          property.isDrawerOpen = !property.isDrawerOpen;
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }

  PopupMenuItem<String> _buildArtifactSwitch(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    User user = Provider.of<User>(context, listen: false);
    return PopupMenuItem<String>(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // value: "value",
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Material(
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
                // Navigator.pop(context, value);
              },
              child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                  leading: Icon(
                    Icons.bar_chart,
                    color: switchArtifact.value ? Colors.blue[400] : null,
                  ),
                  title: Text("可视化",
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Text(
                    "提供图表、动画、地图、网页预览等可视化能力",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  trailing: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: switchArtifact.value,
                      activeColor: Colors.blue[300],
                      onChanged: (value) {
                        setState(() {
                          switchArtifact.value = value;
                          pages.set_artifact(pages.currentPageID, value);
                        });
                        ChatAPI().saveChats(user, pages, pages.currentPageID);
                      },
                    ),
                  )),
            ),
          ));
        }));
  }

  PopupMenuItem<String> _buildInternetSwitch(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    User user = Provider.of<User>(context, listen: false);
    return PopupMenuItem<String>(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // value: "value",
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Material(
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
                // Navigator.pop(context, value);
              },
              child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                  leading: Icon(Icons.language,
                      color: switchInternet.value ? Colors.blue[400] : null),
                  title: Text("联网功能",
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Text(
                    "获取Google搜索的数据",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  trailing: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: switchInternet.value,
                      activeColor: Colors.blue[300],
                      onChanged: (value) {
                        setState(() {
                          switchInternet.value = value;
                          pages.set_internet(pages.currentPageID, value);
                        });
                        ChatAPI().saveChats(user, pages, pages.currentPageID);
                        // Global.saveProperties(internet: property.internet);
                      },
                    ),
                  )),
            ),
          ));
        }));
  }

  PopupMenuItem<String> _buildtemperatureSlide(BuildContext context) {
    // User user = Provider.of<User>(context, listen: false);
    Pages pages = Provider.of<Pages>(context, listen: false);
    return PopupMenuItem<String>(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // value: "value",
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Material(
            //color: Colors.transparent,
            // color: AppColors.drawerBackground,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BORDERRADIUS15,
              ),
              child: InkWell(
                borderRadius: BORDERRADIUS15,
                onTap: null,
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Text("Temperature",
                      style: Theme.of(context).textTheme.titleSmall),
                  title: Container(
                      // margin: EdgeInsets.fromLTRB(0, 0, 15, 10),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Transform.scale(
                          scale: 0.7,
                          child: Slider(
                            min: 0,
                            max: 2,
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            value: temperature,
                            onChanged: (value) {
                              setState(() {
                                temperature = value;
                              });
                            },
                            onChangeEnd: (value) {
                              pages.currentPage?.temperature = value;
                            },
                          ),
                        ),
                      ])),
                  subtitle: Text(
                    "值越大模型思维越发散",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  trailing: Text(
                    "${temperature.toStringAsFixed(1)}",
                    // style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ),
          );
        }));
  }
}
