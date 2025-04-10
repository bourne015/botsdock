import 'package:botsdock/apps/chat/views/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:botsdock/apps/chat/views/bots/bots_centre.dart';
import 'package:provider/provider.dart';
import 'package:botsdock/l10n/gallery_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './models/pages.dart';
import './models/user.dart';
import './models/bot.dart';
import 'main_layout.dart';
import 'routes.dart' as routes;
import './utils/constants.dart';
import './utils/global.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  static const String homeRoute = routes.homeRoute;
  static const String botCentre = routes.botCentre;

  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _AppState();
}

class _AppState extends State<ChatApp> {
  User user = User();
  Pages pages = Pages();
  Property property = Property();
  Bots bots = Bots();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    property.isLoading = true;
    await Global().init(user, pages, property);
    setState(() {
      property.isLoading = false;
    });
    await dotenv.load(fileName: "assets/env.conf");
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => pages),
          ChangeNotifierProvider(create: (context) => property),
          ChangeNotifierProvider(create: (context) => user),
          ChangeNotifierProvider(create: (context) => bots),
        ],
        child: Consumer<User>(builder: (context, _user, _) {
          return MaterialApp(
            title: appTitle,
            themeMode: _user.settings?.themeMode ?? ThemeMode.system,
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
          );
        }));
  }
}
