import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:flutter/material.dart';

//all chat pages
class Settings with ChangeNotifier {
  String _defaultmodel;
  bool _cat;
  double _temperature;
  bool _internet;
  bool _artifact;
  ThemeMode _themeMode;

  Settings({
    String? defaultmodel,
    bool? cat,
    double? temperature,
    bool? internet,
    bool? artifact,
    ThemeMode? themeMode,
  })  : _temperature = temperature ?? 1.0,
        _defaultmodel = defaultmodel ?? DefaultModelVersion.id,
        _cat = cat ?? false,
        _internet = internet ?? false,
        _artifact = artifact ?? false,
        _themeMode = themeMode ?? ThemeMode.system;

  String get defaultmodel => _defaultmodel;
  set defaultmodel(String v) {
    _defaultmodel = v;
  }

  double get temperature => _temperature;
  set temperature(double v) {
    _temperature = v;
    notifyListeners();
  }

  bool get cat => _cat;
  set cat(bool v) {
    _cat = v;
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
        "cat": _cat,
        'temperature': _temperature,
        'internet': _internet,
        "artifact": _artifact,
        'themeMode': _themeMode.toString().split('.').last,
      };

  static Settings fromJson(u) {
    return Settings(
      cat: u["cat"] ?? false,
      temperature: u["temperature"] ?? 1.0,
      internet: u["internet"] ?? false,
      artifact: u["artifact"] ?? false,
      themeMode: ThemeMode.values.firstWhere(
          (e) => e.toString().split('.').last == (u['themeMode'] ?? 'system')),
    );
  }
}
