import 'package:flutter/material.dart';

//all chat pages
class Settings with ChangeNotifier {
  double _temperature;
  bool _internet;
  bool _artifact;
  ThemeMode _themeMode;

  Settings({
    double? temperature,
    bool? internet,
    bool? artifact,
    ThemeMode? themeMode,
  })  : _temperature = temperature ?? 1.0,
        _internet = internet ?? false,
        _artifact = artifact ?? false,
        _themeMode = themeMode ?? ThemeMode.system;

  double get temperature => _temperature;
  set temperature(double v) {
    _temperature = v;
    notifyListeners();
  }

  bool get artifact => _artifact;
  set artifact(bool v) {
    _artifact = v;
    notifyListeners();
  }

  bool get internet => _internet;
  set internet(bool v) {
    _internet = v;
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (_themeMode != value) {
      _themeMode = value;
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() => {
        'temperature': _temperature,
        'internet': _internet,
        "artifact": _artifact,
        'themeMode': _themeMode.toString().split('.').last,
      };

  static Settings fromJson(u) {
    return Settings(
      temperature: u["temperature"] ?? 1.0,
      internet: u["internet"] ?? false,
      artifact: u["artifact"] ?? false,
      themeMode: ThemeMode.values.firstWhere(
          (e) => e.toString().split('.').last == (u['themeMode'] ?? 'system')),
    );
  }
}
