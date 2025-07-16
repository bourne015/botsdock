import 'package:botsdock/apps/chat/vendor/data.dart';
import 'package:flutter/material.dart';

//all chat pages

class Settings {
  final String defaultmodel;
  final bool cat;
  final double temperature;
  final bool internet;
  final bool artifact;
  final ThemeMode themeMode;

  Settings({
    String? defaultmodel,
    this.cat = false,
    this.temperature = 1.0,
    this.internet = false,
    this.artifact = false,
    this.themeMode = ThemeMode.system,
  }) : defaultmodel = defaultmodel ?? DefaultModelVersion.id;

  Settings copyWith({
    String? defaultmodel,
    bool? cat,
    double? temperature,
    bool? internet,
    bool? artifact,
    ThemeMode? themeMode,
  }) {
    return Settings(
      defaultmodel: defaultmodel ?? this.defaultmodel,
      cat: cat ?? this.cat,
      temperature: temperature ?? this.temperature,
      internet: internet ?? this.internet,
      artifact: artifact ?? this.artifact,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        "defaultmodel": defaultmodel,
        "cat": cat,
        'temperature': temperature,
        'internet': internet,
        "artifact": artifact,
        'themeMode': themeMode.toString().split('.').last,
      };

  static Settings fromJson(dynamic u) {
    return Settings(
      defaultmodel: u["defaultmodel"] ?? DefaultModelVersion.id,
      cat: u["cat"] ?? false,
      temperature: u["temperature"] ?? 1.0,
      internet: u["internet"] ?? false,
      artifact: u["artifact"] ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString().split('.').last == (u['themeMode'] ?? 'system'),
        orElse: () => ThemeMode.system,
      ),
    );
  }
}
