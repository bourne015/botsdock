import 'package:flutter/material.dart';
import 'package:gallery/studies/reply/routes.dart' as routes;

import "home.dart";

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
          fontFamily: "GalleryIcons",
          primarySwatch: Colors.blueGrey,
        ),
        home: const InitPage(),
        initialRoute: ChatApp.homeRoute);
  }
}
