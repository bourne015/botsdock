import 'package:ansicolor/ansicolor.dart';
import 'package:flutter/foundation.dart';

enum LogColor { none, red, green, yellow, blue }

class Logger {
  static final AnsiPen _redPen = AnsiPen()..red(bold: false);
  static final AnsiPen _greenPen = AnsiPen()..green();
  static final AnsiPen _yellowPen = AnsiPen()..yellow();
  static final AnsiPen _bluePen = AnsiPen()..blue();

  static void _coloredlog(String message, LogColor color) {
    switch (color) {
      case LogColor.red:
        debugPrint(_redPen(message));
        break;
      case LogColor.green:
        debugPrint(_greenPen(message));
        break;
      case LogColor.yellow:
        debugPrint(_yellowPen(message));
        break;
      case LogColor.blue:
        debugPrint(_bluePen(message));
        break;
      case LogColor.none:
        break;
    }
  }

  static void info(String message, {LogColor? color = LogColor.none}) {
    if (color != null)
      _coloredlog(message, color);
    else
      debugPrint(message);
  }

  static void warn(String message, {LogColor? color = LogColor.yellow}) {
    if (color != null)
      _coloredlog(message, color);
    else
      debugPrint(message);
  }

  static void error(String message, {LogColor? color = LogColor.red}) {
    if (color != null)
      _coloredlog(message, color);
    else
      debugPrint(message);
  }
}
