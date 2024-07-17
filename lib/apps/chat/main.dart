import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './models/pages.dart';
import './models/user.dart';
import 'main_layout.dart';
import 'routes.dart' as routes;
import './utils/constants.dart';
import './utils/global.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  static const String homeRoute = routes.homeRoute;

  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _AppState();
}

class _AppState extends State<ChatApp> {
  User user = User();
  Pages pages = Pages();
  Property property = Property();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Global().init(user, pages);
    setState(() {
      property.isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => pages),
          ChangeNotifierProvider(create: (context) => property),
          ChangeNotifierProvider(create: (context) => user),
        ],
        child: MaterialApp(
          title: appTitle,
          theme: ThemeData(
            fontFamily: 'notosans',
            primarySwatch: AppColors.theme,
          ),
          initialRoute: ChatApp.homeRoute,
          routes: {
            ChatApp.homeRoute: (context) => const MainLayout(),
          },
        ));
  }
}
