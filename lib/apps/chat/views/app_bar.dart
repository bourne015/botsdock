import 'package:botsdock/apps/chat/models/mcp/mcp_models.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_providers.dart';
import 'package:botsdock/apps/chat/models/mcp/mcp_settings_providers.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/vendor/chat_api.dart';
import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:botsdock/apps/chat/views/menu/mcp_connection_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:provider/provider.dart';

import '../utils/utils.dart';
import '../utils/constants.dart';
import '../models/pages.dart';

class MyAppBar extends rp.ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const MyAppBar({Key? key}) : super(key: key);
  @override
  rp.ConsumerState<MyAppBar> createState() => MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}

class MyAppBarState extends rp.ConsumerState<MyAppBar> with RestorationMixin {
  double temperature = 1;
  RestorableBool switchArtifact = RestorableBool(true);
  RestorableBool switchInternet = RestorableBool(true);
  final flag_artifact = Tooltip(
    message: "artifact",
    child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        child: Icon(Icons.bar_chart, color: Colors.blue[400], size: 18)),
  );
  final flag_network = Tooltip(
    message: "network",
    child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        child: Icon(Icons.language, color: Colors.blue[400], size: 18)),
  );

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
    final propertyState = ref.read(propertyProvider);
    Pages pages = Provider.of<Pages>(context);
    User user = ref.watch(userProvider);
    if (propertyState.onInitPage) {
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
        leading: !isDisplayDesktop(context) ? appbarLeading(context) : null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appbarTitle(context),
            SizedBox(width: 10),
            ...appbarIcons(pages),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 44,
        centerTitle: true,
        actions: [
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

  List<Widget> appbarIcons(Pages pages) {
    List<Widget> res = [];
    final mcpState = ref.watch(mcpClientProvider);
    final connectedCount = mcpState.connectedServerCount;
    final propertyState = ref.watch(propertyProvider);
    if (!propertyState.onInitPage &&
        pages.currentPage!.model != Models.deepseekReasoner.id) {
      if (pages.currentPage!.artifact && pages.currentPage!.internet)
        res = [flag_artifact, flag_network];
      else if (pages.currentPage!.artifact)
        res = [flag_artifact];
      else if (pages.currentPage!.internet) res = [flag_network];
    }

    if (!propertyState.onInitPage && connectedCount > 0)
      res.add(
        Tooltip(
          message: "$connectedCount MCP connected",
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            margin: EdgeInsets.symmetric(horizontal: 7),
            constraints: BoxConstraints(maxWidth: 50),
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.blue[400]!, width: 0.5),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              "$connectedCount mcp",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      );
    return res;
  }

  bool isSupportTools(Pages pages) {
    final propertyState = ref.read(propertyProvider);
    if (propertyState.onInitPage)
      return propertyState.initModelVersion != Models.deepseekReasoner.id;
    else
      return pages.currentPage!.model != Models.deepseekReasoner.id;
  }

  Widget _appBarMenu(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    User user = ref.watch(userProvider);
    final propertyState = ref.watch(propertyProvider);
    // final serverList = ref.read(mcpServerListProvider);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded),
      // color: AppColors.drawerBackground,
      shadowColor: Colors.blue,
      elevation: 5,
      position: PopupMenuPosition.under,
      padding: const EdgeInsets.only(left: 2),
      shape: RoundedRectangleBorder(borderRadius: BORDERRADIUS10),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (!propertyState.onInitPage)
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
        if (isSupportTools(pages)) _buildArtifactSwitch(context),
        if (isSupportTools(pages)) PopupMenuDivider(),
        if (isSupportTools(pages)) _buildInternetSwitch(context),
        if (isSupportTools(pages)) PopupMenuDivider(),
        _buildtemperatureSlide(context),
        // if (serverList.isNotEmpty) PopupMenuDivider(),
        // PopupMenuItem(
        //   enabled: false,
        //   child: Text(GalleryLocalizations.of(context)!.mcpServers),
        // ),
        // if (serverList.isNotEmpty) _buildMCPlist(context),
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

  PopupMenuItem<String> _buildMCPlist(
    BuildContext context,
  ) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.symmetric(horizontal: 0),
      value: "mcp",
      child: rp.Consumer(
        builder: (context, ref, child) {
          final serverList = ref.watch(mcpServerListProvider);
          final mcpState = ref.watch(mcpClientProvider);
          final serverStatuses = mcpState.serverStatuses;
          double _height = serverList.length * 70;
          return Material(
              child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: _height <= 210 ? _height : 270,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: serverList.map<Widget>((server) {
                  final status = serverStatuses[server.id] ??
                      McpConnectionStatus.disconnected;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                      leading: Tooltip(
                        message: status.name,
                        child: McpConnectionStatusIndicator(
                            status: status, name: server.name),
                      ),
                      title: Text(
                        server.name,
                        style: TextStyle(
                          fontWeight: server.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Tooltip(
                        waitDuration: Duration(milliseconds: 600),
                        message: '${server.description}'.trim(),
                        child: Text(
                          '${server.description}'.trim(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: server.isActive,
                          activeColor: Colors.blue[300],
                          onChanged: (bool value) {
                            _toggleServerActive(server.id, value);
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ));
        },
      ),
    );
  }

  void _toggleServerActive(String serverId, bool isActive) {
    ref
        .read(settingsServiceProvider)
        .toggleMcpServerActive(serverId, isActive)
        .catchError(
          (e) => _showSnackbar('Error updating server active state: $e'),
        );
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget appbarTitle(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    double _width = 130;

    if (isDisplayDesktop(context)) _width = 300;
    return Tooltip(
      message: pages.currentPageID > -1 ? pages.currentPage!.model : "",
      child: Container(
        constraints: BoxConstraints(maxWidth: _width),
        child: Text(
          pages.currentPageID > -1 ? pages.currentPage!.model : "",
          maxLines: 1,
          // style: const TextStyle(fontSize: 16, color: AppColors.appBarText),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget appbarLeading(BuildContext context) {
    final propertyState = ref.watch(propertyProvider);
    final propertyNotifier = ref.watch(propertyProvider.notifier);
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        if (isDisplayDesktop(context)) {
          propertyNotifier.setIsDrawerOpen(!propertyState.isDrawerOpen);
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }

  PopupMenuItem<String> _buildArtifactSwitch(BuildContext context) {
    Pages pages = Provider.of<Pages>(context, listen: false);
    User user = ref.watch(userProvider);
    final propertyState = ref.read(propertyProvider);
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
                          if (propertyState.onInitPage)
                            ref
                                .read(userProvider.notifier)
                                .updateArtifact(value);
                          else
                            pages.set_artifact(pages.currentPageID, value);
                        });
                        if (!propertyState.onInitPage)
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
    User user = ref.watch(userProvider);
    final propertyState = ref.read(propertyProvider);
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
                          if (propertyState.onInitPage)
                            ref
                                .read(userProvider.notifier)
                                .updateInternet(value);
                          else
                            pages.set_internet(pages.currentPageID, value);
                        });
                        if (!propertyState.onInitPage)
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
    Pages pages = Provider.of<Pages>(context, listen: false);
    final propertyState = ref.read(propertyProvider);
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
                            min: -0.1,
                            max: 2,
                            divisions: 100,
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            value: temperature,
                            onChanged: (value) {
                              setState(() {
                                temperature = value;
                              });
                            },
                            onChangeEnd: (value) {
                              if (propertyState.onInitPage)
                                ref
                                    .read(userProvider.notifier)
                                    .updateTemperature(value);
                              else
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
                    "${temperature.toStringAsFixed(2)}",
                    // style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ),
          );
        }));
  }
}
