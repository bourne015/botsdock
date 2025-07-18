import 'dart:math';

import 'package:botsdock/apps/chat/utils/client/dio_client.dart';
import 'package:botsdock/apps/chat/views/menu/mcp_server_list.dart';
import 'package:botsdock/apps/chat/views/menu/user_management.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:provider/provider.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';

import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:botsdock/apps/chat/utils/custom_widget.dart';
import 'package:botsdock/apps/chat/utils/utils.dart';
import 'package:botsdock/apps/chat/models/user.dart';
import 'package:botsdock/apps/chat/models/pages.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/apps/chat/views/menu/user_info.dart';
import 'package:botsdock/apps/chat/views/menu/settings_view.dart';

class Administrator extends rp.ConsumerWidget {
  Administrator({Key? key}) : super(key: key);

  final _newBotController1 = TextEditingController();
  final _newBotController2 = TextEditingController();
  final dio = DioClient();
  final Random random = Random();
  final GlobalKey<PopupMenuButtonState<String>> _popupMenuKey = GlobalKey();

  // @override
  // void initState() {}

  // @override
  // void Dispose() {
  //   _emailcontroller.dispose();
  //   _namecontroller.dispose();
  //   _pwdcontroller.dispose();
  //   _pwdconfirmcontroller.dispose();
  // }

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    User user = ref.watch(userProvider);
    Pages pages = Provider.of<Pages>(context, listen: false);
    final propertyNotifier = ref.read(propertyProvider.notifier);
    return PopupMenuButton<String>(
        key: _popupMenuKey,
        // color: AppColors.drawerBackground,
        shadowColor: Colors.blue,
        elevation: 15,
        shape: RoundedRectangleBorder(
          borderRadius: BORDERRADIUS10,
        ),
        child: UserThumbnail(
          color: Theme.of(context).colorScheme.secondaryContainer,
          user: user,
          onTap: () {
            _popupMenuKey.currentState?.showButtonMenu();
          },
        ),
        ////////
        padding: const EdgeInsets.only(left: 2),
        onSelected: (String value) async {
          switch (value) {
            case 'user':
              // userInfoDialog(context, user);
              break;
            // case 'Login':
            //   loginDialog(context, ref);
            // break;
            case 'Customize ChatGPT':
              //NewBotDialog(context);
              break;
            case 'Instructions':
              InstructionsDialog(context, user, ref);
              break;
            case 'mcpsettings':
              McpDialog(context, user);
              break;
            case 'About':
              aboutDialog(context);
              break;
            case 'Logout':
              ref.read(userProvider.notifier).reset();
              propertyNotifier.reset();
              pages.reset();
              await Global.reset();
              break;
            default:
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (user.isLogedin)
                PopupMenuItem(
                  enabled: false,
                  height: 80,
                  padding: EdgeInsets.all(0),
                  value: "user",
                  child: MenuItemUserThumbnail(
                    user: user,
                    enabled: false,
                    radius: 40,
                    height: 80,
                  ),
                ),
              if (user.isLogedin) PopupMenuDivider(),
              // _buildPopupMenuItem(
              //     context,
              //     "Customize ChatGPT",
              //     Icons.add_home_outlined,
              //     GalleryLocalizations.of(context)!.custmizeGPT),
              SettingsMenuItem(
                context,
                "Instructions",
                Icons.settings_rounded,
                GalleryLocalizations.of(context)!.setting,
              ),
              SettingsMenuItem(
                context,
                "mcpsettings",
                Icons.construction,
                "MCP",
              ),
              SettingsMenuItem(context, "About", Icons.info,
                  GalleryLocalizations.of(context)!.about),
              // PopupMenuDivider(),
              // _buildPopupMenuItem(context, "Logout", Icons.logout,
              //     GalleryLocalizations.of(context)!.logout),
            ]);
  }

  void InstructionsDialog(BuildContext context, User user, rp.WidgetRef ref) {
    final GlobalKey<SettingsViewState> settingsKey =
        GlobalKey<SettingsViewState>();
    // showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: Text('模型介绍'),
    //         content: modelINFO(context),
    //       );
    //     });
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              child: ClipRRect(
            borderRadius: BORDERRADIUS15,
            child: PopScope(
              onPopInvokedWithResult: (bool didPop, dynamic result) async {
                if (didPop) {
                  settingsKey.currentState?.saveSetting();
                }
              },
              child: SettingsView(key: settingsKey),
            ),
          ));
        });
  }

  void McpDialog(BuildContext context, User user) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              child: ClipRRect(
            borderRadius: BORDERRADIUS15,
            child: MCPConfig(user: user),
          ));
        });
  }

  void userInfoDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserInfo(user: user),
    );
  }

  void aboutDialog(BuildContext context) async {
    String _version = await getVersionNumber();
    var content = aboutText + '\nVersion $_version';
    notifyBox(context: context, title: 'About', content: content);
  }

  void NewBotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Customize ChatGPT'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Custom Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  maxLines: 5,
                  maxLength: 2048,
                  controller: _newBotController1,
                  decoration: InputDecoration(
                    hintText: 'e.g., Information specific to my needs',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 254, 254, 254))),
                    hintStyle: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(height: 20),
                Text('How would you like ChatGPT to respond?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  maxLines: 5,
                  maxLength: 2048,
                  controller: _newBotController2,
                  decoration: InputDecoration(
                    hintText: 'e.g., Be concise and direct',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 254, 254, 254))),
                    hintStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                // Implement your save logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
