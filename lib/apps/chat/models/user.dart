import 'dart:convert';

import 'package:botsdock/apps/chat/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserStatus { loggedOut, loggedIn, loading }

//all chat pages
class User {
  final bool isLogedin;
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? avatar_bot;
  final String? cat_id;
  final double? credit;
  final bool signUP;
  final int updated_at;
  final Settings? settings;
  final String? token;
  final UserStatus? status;

  const User({
    this.isLogedin = false,
    this.id = 0,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.avatar_bot,
    this.cat_id,
    this.credit,
    this.signUP = false,
    this.updated_at = 0,
    this.settings,
    this.token,
    this.status,
  });

  User copyWith({
    bool? isLogedin,
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? avatar_bot,
    String? cat_id,
    double? credit,
    bool? signUP,
    int? updated_at,
    Settings? settings,
    String? token,
    UserStatus? status,
  }) {
    return User(
      isLogedin: isLogedin ?? this.isLogedin,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      avatar_bot: avatar_bot ?? this.avatar_bot,
      cat_id: cat_id ?? this.cat_id,
      credit: credit ?? this.credit,
      signUP: signUP ?? this.signUP,
      updated_at: updated_at ?? this.updated_at,
      settings: settings ?? this.settings,
      token: token ?? this.token,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        "email": email,
        "phone": phone,
        "avatar": avatar,
        "avatar_bot": avatar_bot,
        "cat_id": cat_id,
        "credit": credit,
        "isLogedin": isLogedin,
        "updated_at": updated_at,
        "settings": settings?.toJson(),
      };

  static User fromJson(dynamic u) {
    Map<String, dynamic> settingsJson = {};
    if (u["settings"] != null) {
      if (u["settings"] is Map) {
        settingsJson = Map<String, dynamic>.from(u["settings"]);
      } else if (u["settings"] is String) {
        try {
          settingsJson = jsonDecode(u["settings"]);
        } catch (e) {
          print('Error parsing settings JSON: $e');
        }
      }
    }
    return User(
      id: u["id"] as int,
      name: u["name"],
      email: u["email"],
      phone: u["phone"],
      avatar: u["avatar"],
      avatar_bot: u["avatar_bot"],
      cat_id: u["cat_id"],
      credit: u["credit"],
      updated_at: u["updated_at"] as int,
      isLogedin: u["isLogedin"] ?? false,
      settings: Settings.fromJson(settingsJson),
    );
  }
}

class UserNotifier extends Notifier<User> {
  @override
  User build() {
    return User(
      status: UserStatus.loggedOut,
      settings: Settings(), // 确保有默认的 Settings
    );
  }

  // void updateId(int id) {
  //   state = state.copyWith(id: id);
  // }

  // void updateUpdatedAt(int updatedAt) {
  //   state = state.copyWith(updated_at: updatedAt);
  // }

  // void updateName(String? name) {
  //   state = state.copyWith(name: name);
  // }

  // void updateEmail(String? email) {
  //   state = state.copyWith(email: email);
  // }

  // void updatePhone(String? phone) {
  //   state = state.copyWith(phone: phone);
  // }

  // void updateAvatar(String? avatar) {
  //   state = state.copyWith(avatar: avatar);
  // }

  // void updateAvatarBot(String? avatarBot) {
  //   state = state.copyWith(avatar_bot: avatarBot);
  // }

  // void updateIsLogedin(bool isLogedin) {
  //   state = state.copyWith(isLogedin: isLogedin);
  // }

  // void updateSignUP(bool signUP) {
  //   state = state.copyWith(signUP: signUP);
  // }

  // void updateCatId(String? catId) {
  //   state = state.copyWith(cat_id: catId);
  // }

  // void updateCredit(double? credit) {
  //   state = state.copyWith(credit: credit);
  // }

  void updateSettings(Settings? settings) {
    state = state.copyWith(settings: settings);
  }

  void updateThemeMode(ThemeMode themeMode) {
    final currentSettings = state.settings ?? Settings();
    final newSettings = currentSettings.copyWith(themeMode: themeMode);
    state = state.copyWith(settings: newSettings);
  }

  void updateCat(bool cat) {
    final currentSettings = state.settings ?? Settings();
    final newSettings = currentSettings.copyWith(cat: cat);
    state = state.copyWith(settings: newSettings);
  }

  void updateTemperature(double temperature) {
    final currentSettings = state.settings ?? Settings();
    final newSettings = currentSettings.copyWith(temperature: temperature);
    state = state.copyWith(settings: newSettings);
  }

  void updateDefaultModel(String model) {
    final currentSettings = state.settings ?? Settings();
    final newSettings = currentSettings.copyWith(defaultmodel: model);
    state = state.copyWith(settings: newSettings);
  }

  void updateInternet(bool internet) {
    final currentSettings = state.settings ?? Settings();
    final newSettings = currentSettings.copyWith(internet: internet);
    state = state.copyWith(settings: newSettings);
  }

  void updateArtifact(bool artifact) {
    final currentSettings = state.settings ?? Settings();
    final newSettings = currentSettings.copyWith(artifact: artifact);
    state = state.copyWith(settings: newSettings);
  }

  void reset() {
    state = User(
      status: UserStatus.loggedOut,
      settings: Settings(),
    );
  }

  void update({
    bool? isLogedin,
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? avatar_bot,
    String? cat_id,
    double? credit,
    bool? signUP,
    int? updated_at,
    Settings? settings,
    String? access_token,
    UserStatus? status,
  }) {
    state = state.copyWith(
      isLogedin: isLogedin,
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatar: avatar,
      avatar_bot: avatar_bot,
      cat_id: cat_id,
      credit: credit,
      signUP: signUP,
      updated_at: updated_at,
      settings: settings,
      token: access_token,
      status: status,
    );
  }

  void copy(User user) {
    state = user;
  }
}

final userProvider = NotifierProvider<UserNotifier, User>(() {
  return UserNotifier();
});
