import 'package:botsdock/apps/chat/models/mcp/mcp_settings_providers.dart';
import 'package:botsdock/apps/chat/utils/global.dart';
import 'package:botsdock/data/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/apps/chat/views/bots/bots_centre.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:provider/provider.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './models/pages.dart';
import './models/user.dart';
import './models/bot.dart';
import 'main_layout.dart';
import 'routes.dart' as routes;
import './utils/constants.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends rp.ConsumerStatefulWidget {
  static const String homeRoute = routes.homeRoute;
  static const String botCentre = routes.botCentre;

  ChatApp({super.key});

  @override
  rp.ConsumerState<ChatApp> createState() => _AppState();
}

class _AppState extends rp.ConsumerState<ChatApp> {
  Pages pages = Pages();
  Bots bots = Bots();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final user = ref.read(userProvider);
    final propertyNotifier = ref.read(propertyProvider.notifier);

    await _initData(user, pages, propertyNotifier);
  }

  Future<void> _initData(
    User user,
    Pages pages,
    PropertyNotifier propertyNotifier,
  ) async {
    print("init chat");
    if (!user.isLogedin) {
      await Global.restoreLocalUser(user, ref);
      user = ref.read(userProvider);
    }
    if (user.isLogedin) {
      print("restore chat");
      await Global.restoreChats(user, pages, propertyNotifier);
      await ref.read(mcpServerListProvider.notifier).refresh();
    }

    await dotenv.load(fileName: "assets/env.conf");
  }

  @override
  Widget build(BuildContext context) {
    User user = ref.watch(userProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => pages),
        // ChangeNotifierProvider(create: (context) => property),
        // ChangeNotifierProvider(create: (context) => user),
        ChangeNotifierProvider(create: (context) => bots),
      ],
      child: MaterialApp(
        title: appTitle,
        themeMode: user.settings?.themeMode ?? ThemeMode.system,
        theme: ChatThemeData.lightThemeData.copyWith(
          platform: defaultTargetPlatform,
        ),
        darkTheme: ChatThemeData.darkThemeData.copyWith(
          platform: defaultTargetPlatform,
        ),
        initialRoute: ChatApp.homeRoute,
        routes: {
          ChatApp.homeRoute: (context) => const MainLayout(),
          ChatApp.botCentre: (context) => const BotsCentre(),
        },
        localizationsDelegates: GalleryLocalizations.localizationsDelegates,
        supportedLocales: [
          Locale('zh'),
        ],
      ),
    );
  }
}
