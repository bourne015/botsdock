import 'package:flutter/widgets.dart';

//all chat pages
class Settings with ChangeNotifier {
  double _temperature;
  bool _internet;
  bool _artifact;

  Settings({
    double? temperature,
    bool? internet,
    bool? artifact,
  })  : _temperature = temperature ?? 1.0,
        _internet = internet ?? true,
        _artifact = artifact ?? true;

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

  Map<String, dynamic> toJson() => {
        'temperature': _temperature,
        'internet': _internet,
        "artifact": _artifact,
      };

  static Settings fromJson(u) {
    return Settings(
      temperature: u["temperature"] ?? 1.0,
      internet: u["internet"] ?? true,
      artifact: u["artifact"] ?? true,
    );
  }
}
