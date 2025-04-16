// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:botsdock/apps/chat/utils/constants.dart';
import 'package:flutter/material.dart';

class ChatThemeData {
  static const _lightFillColor = Colors.black;
  static const _darkFillColor = Colors.white;

  static final Color _lightFocusColor = Colors.black.withValues(alpha: 0.12);
  static final Color _darkFocusColor = Colors.white.withValues(alpha: 0.12);

  static ThemeData lightThemeData =
      themeData(lightColorScheme, _lightFocusColor);
  static ThemeData darkThemeData = themeData(darkColorScheme, _darkFocusColor);

  static ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
    return ThemeData(
        colorScheme: colorScheme,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: colorScheme.primary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(
            color: AppColors.gray,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gray25, width: 1.0),
              borderRadius: BORDERRADIUS10),
          focusedBorder: OutlineInputBorder(borderRadius: BORDERRADIUS10),
          // outlineBorder: const BorderSide(color: AppColors.gray25, width: 1.0),
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        canvasColor: colorScheme.surface,
        scaffoldBackgroundColor: colorScheme.surface,
        highlightColor: Colors.transparent,
        focusColor: focusColor,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color.alphaBlend(
            _lightFillColor.withValues(alpha: 0.80),
            _darkFillColor,
          ),
          contentTextStyle:
              _textTheme.titleMedium!.apply(color: _darkFillColor),
        ),
        dividerTheme: DividerThemeData(
            thickness: 1, indent: 10, endIndent: 10, color: AppColors.divider),
        cardTheme: CardThemeData(
          color: colorScheme.secondaryContainer,
          elevation: 2,
        ));
  }

  static const ColorScheme lightColorScheme = ColorScheme(
    primary: Color.fromARGB(255, 108, 159, 247), //Color(0xffbb86fc),
    primaryContainer: Color(0xFF117378),
    secondary: Color.fromARGB(255, 228, 242, 242),
    secondaryFixed: Color.fromARGB(255, 223, 223, 223),
    secondaryContainer: Color.fromARGB(255, 244, 244, 244),
    // background: Color(0xFFE6EBEB),
    surface: Color(0xFFFAFBFB),
    // onBackground: Colors.white,
    tertiary: Color.fromARGB(255, 223, 223, 223),
    error: _lightFillColor,
    onError: _lightFillColor,
    onPrimary: _lightFillColor,
    onSecondary: Color(0xFF322942),
    onSurface: Color(0xFF241E30),
    brightness: Brightness.light,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    primary: Colors.blueAccent, //Color(0xFF33333D),
    primaryContainer: Color(0xFF1CDEC9),
    secondary: Color(0xFFc3c5dd),
    secondaryFixed: Color(0xff38393f), //chat tab selected
    secondaryContainer: Color(0xFF292a2f), // draw, bottab, modelseltab
    surface: Color(0xff38393f), // chat, init page
    tertiary: Color(0xFF292a2f),
    error: _darkFillColor,
    onError: _darkFillColor,
    onPrimary: _darkFillColor,
    onSecondary: _darkFillColor,
    onSurface: _darkFillColor,
    brightness: Brightness.dark,
  );

  // static const _light = FontWeight.w300;
  static const _regular = FontWeight.w400;
  static const _medium = FontWeight.w500;
  static const _semiBold = FontWeight.w600;
  static const _bold = FontWeight.w700;

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontWeight: _bold,
      fontSize: 57.0,
      color: Colors.grey,
    ),
    headlineLarge: TextStyle(fontWeight: _regular, fontSize: 32.0),
    headlineMedium: TextStyle(fontWeight: _regular, fontSize: 28.0),
    //一级标题: bot centre title
    headlineSmall: TextStyle(fontWeight: _regular, fontSize: 24.0),

    //二级标题: explore
    titleLarge: TextStyle(fontWeight: _medium, fontSize: 22.0),
    //三级标题: bot name
    titleMedium: TextStyle(fontWeight: _semiBold, fontSize: 16.0),
    //function tools title
    titleSmall: TextStyle(fontWeight: _medium, fontSize: 14.5),

    //new chat,bot centre, appbar model
    bodyLarge: TextStyle(fontWeight: _regular, fontSize: 16.0),
    //正文
    //newbot textfield title, chat text，about content
    //model select name, 'Chat', bot card, desctrition
    bodyMedium: TextStyle(fontWeight: _regular, fontSize: 14.5),
    bodySmall: TextStyle(fontWeight: _regular, fontSize: 12.0),

    //chat tab, theme switch
    labelLarge: TextStyle(fontWeight: _medium, fontSize: 14.5),
    //bot author, chat group date
    labelMedium: TextStyle(
      fontWeight: _medium,
      fontSize: 12,
      color: Colors.grey,
    ),
    labelSmall: TextStyle(
      fontWeight: _regular,
      fontSize: 10.5,
      color: Colors.grey,
    ),
  );
}
