import 'package:flutter/material.dart';
import 'package:gallery/studies/chat/routes.dart' as routes;

import 'home.dart';

class ChatApp extends StatefulWidget {
  static const String homeRoute = routes.homeRoute;

  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _AppState();
}

class _AppState extends State<ChatApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',
      theme: ThemeData(
        fontFamily: 'GalleryIcons',
        primarySwatch: Colors.blueGrey,
      ),
      initialRoute: ChatApp.homeRoute,
      routes: {
        ChatApp.homeRoute: (context) => const InitPage(),
      },
    );
  }
}
