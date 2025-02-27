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
  RestorableBool switchArtifact = RestorableBool(true);
  RestorableBool switchInternet = RestorableBool(true);

  @override
  String get restorationId => 'switch_test';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(switchArtifact, 'switch_artifact');
    registerForRestoration(switchInternet, 'switch_internet');
  }

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Property property = Provider.of<Property>(context);
    Pages pages = Provider.of<Pages>(context);
    if (property.onInitPage) {
      switchArtifact.value = property.artifact;
      switchInternet.value = property.internet;
    } else {
      switchArtifact.value = pages.currentPage!.artifact;
      switchInternet.value = pages.currentPage!.internet;
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
            if (!property.onInitPage && pages.currentPage!.artifact)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.auto_graph, color: Colors.blue[700]),
              ),
            if (!property.onInitPage && pages.currentPage!.internet)
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.cloud, color: Colors.yellow[800])),
          ],
        ),
        backgroundColor: AppColors.chatPageBackground,
        surfaceTintColor: AppColors.chatPageBackground,
        toolbarHeight: 44,
        centerTitle: true,
        actions: [
          if (!property.onInitPage) _appBarMenu(context),
        ],
      ),
      // Divider(
      //   height: 1.0,
      //   thickness: 1.0,
      //   color: AppColors.drawerDivider,
      // ),
    ]);
  }

  Widget _appBarMenu(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 20),
      color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      position: PopupMenuPosition.under,
      padding: const EdgeInsets.only(left: 2),
      shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS10),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(
          context,
          "clear",
          icon: Icon(Icons.delete_outline, size: 18),
          title: "清空当前页面",
          onTap: () {
            Navigator.of(context).pop();
            pages.clearCurrentPage();
          },
        ),
        PopupMenuDivider(),
        _buildArtifactSwitch(context),
        _buildInternetSwitch(context)
      ],
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
            padding: EdgeInsets.symmetric(horizontal: 5),
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

  Widget appbarTitle(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return RichText(
        text: TextSpan(
      text: pages.currentPageID > -1 ? pages.currentPage!.model : "",
      style: const TextStyle(fontSize: 16, color: AppColors.appBarText),
    ));
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
    return PopupMenuItem<String>(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // value: "value",
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Material(
              //color: Colors.transparent,
              color: AppColors.drawerBackground,
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
                        Icons.auto_graph,
                        color: switchArtifact.value ? Colors.blue[700] : null,
                      ),
                      title: Text("可视化(Beta)"),
                      subtitle: Text("提供图表、动画、地图、网页预览等可视化内容",
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.subTitle)),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: switchArtifact.value,
                          activeColor: Colors.blue[300],
                          onChanged: (value) {
                            setState(() {
                              switchArtifact.value = value;
                              pages.currentPage!.artifact =
                                  switchArtifact.value;
                              pages.notifyListeners();
                            });
                          },
                        ),
                      )),
                ),
              ));
        }));
  }

  PopupMenuItem<String> _buildInternetSwitch(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    return PopupMenuItem<String>(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // value: "value",
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Material(
              //color: Colors.transparent,
              color: AppColors.drawerBackground,
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
                      leading: Icon(Icons.cloud,
                          color:
                              switchInternet.value ? Colors.yellow[800] : null),
                      title: Text("联网功能(Beta)"),
                      subtitle: Text("获取Google搜索的结果",
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.subTitle)),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: switchInternet.value,
                          activeColor: Colors.blue[300],
                          onChanged: (value) {
                            setState(() {
                              switchInternet.value = value;
                              pages.currentPage!.internet =
                                  switchInternet.value;
                              pages.notifyListeners();
                            });
                            // Global.saveProperties(internet: property.internet);
                          },
                        ),
                      )),
                ),
              ));
        }));
  }
}
