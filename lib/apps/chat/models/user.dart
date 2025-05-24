import 'dart:convert';

import 'package:botsdock/apps/chat/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

//all chat pages
class User with ChangeNotifier {
  bool _isLogedin = false;
  int _id = 0;
  String? _name;
  String? _email;
  String? _phone;
  String? _avatar;
  String? _avatar_bot;
  String? _cat_id;
  double? _credit;
  bool _signUP = false;
  int _updated_at = 0;
  Settings? _settings;
  String? token;

  User({
    bool? isLogedin,
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? avatar_bot,
    String? cat_id,
    double? credit,
    bool? signUP = true,
    int? updated_at = 0,
    Settings? settings,
    String? token,
  })  : _isLogedin = isLogedin ?? false,
        _id = id ?? 0,
        _name = name,
        _email = email,
        _phone = phone,
        _avatar = avatar,
        _avatar_bot = avatar_bot,
        _cat_id = cat_id,
        _credit = credit,
        _signUP = signUP ?? false,
        _settings = settings ?? Settings(),
        _updated_at = updated_at ?? 0;

  int get id => _id;
  set id(int user_id) {
    _id = user_id;
  }

  int get updated_at => _updated_at;
  set updated_at(int updated_time) {
    _updated_at = updated_time;
  }

  String? get name => _name;
  set name(String? name) {
    _name = name;
  }

  String? get email => _email;
  set email(String? mail) {
    _email = mail;
  }

  String? get phone => _phone;
  set phone(String? num) {
    _phone = num;
  }

  String? get avatar => _avatar;
  set avatar(String? newavatar) {
    _avatar = newavatar;
    notifyListeners();
  }

  String? get avatar_bot => _avatar_bot;
  set avatar_bot(String? newavatar) {
    _avatar_bot = newavatar;
    notifyListeners();
  }

  bool get isLogedin => _isLogedin;
  set isLogedin(bool v) {
    _isLogedin = v;
    notifyListeners();
  }

  bool get signUP => _signUP;
  set signUP(bool v) {
    _signUP = v;
    notifyListeners();
  }

  String? get cat_id => _cat_id;
  set cat_id(String? v) {
    _cat_id = v;
  }

  double? get credit => _credit;
  set credit(double? recharge) {
    _credit = recharge;
  }

  void reset() {
    _isLogedin = false;
    notifyListeners();
  }

  Settings? get settings => _settings;
  set settings(Settings? value) {
    _settings = value;
    notifyListeners();
  }

  set themeMode(ThemeMode v) {
    _settings?.themeMode = v;
    notifyListeners();
  }

  set cat(bool v) {
    _settings?.cat = v;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'id': _id,
        'name': _name,
        "email": _email,
        "phone": _phone,
        "avatar": _avatar,
        "avatar_bot": _avatar_bot,
        "cat_id": _cat_id,
        "credit": _credit,
        "isLogedin": _isLogedin,
        "updated_at": _updated_at,
        "settings": settings?.toJson(),
      };

  static User fromJson(u) {
    Map<String, dynamic> settingsJson = {};
    if (u["settings"] != null) {
      if (u["settings"] is Map) {
        settingsJson = Map<String, dynamic>.from(u["settings"]);
      } else if (u["settings"] is String) {
        // 如果后端返回的是JSON字符串，需要解析
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
  }) {
    if (isLogedin != null) _isLogedin = isLogedin;
    if (id != null) _id = id;
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (avatar != null) _avatar = avatar;
    if (avatar_bot != null) _avatar_bot = avatar_bot;
    if (cat_id != null) _cat_id = cat_id;
    if (credit != null) _credit = credit;
    if (signUP != null) _signUP = signUP;
    if (updated_at != null) _updated_at = updated_at;
    if (settings != null) _settings = settings;
    if (access_token != null) token = access_token;
    notifyListeners();
  }

  void copy(User u) {
    _isLogedin = u.isLogedin;
    _id = u.id;
    _signUP = u.signUP;
    _updated_at = u.updated_at;
    if (u.name != null) _name = u.name;
    if (u.email != null) _email = u.email;
    if (u.phone != null) _phone = u.phone;
    if (u.avatar != null) _avatar = u.avatar;
    if (u.avatar_bot != null) _avatar_bot = u.avatar_bot;
    if (u.cat_id != null) _cat_id = u.cat_id;
    if (u.credit != null) _credit = u.credit;
    if (u.settings != null) _settings = u.settings;
    if (u.token != null) token = u.token;
    notifyListeners();
  }
}
