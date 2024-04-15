import 'package:flutter/widgets.dart';

//all chat pages
class User with ChangeNotifier {
  bool _isLogedin = false;
  int _id = 0;
  String? _name;
  String? _email;
  String? _phone;
  String? _avatar;
  bool _signUP = true;
  int _updated_at = 0;

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
  set avatar(String? avatarNum) {
    _avatar = avatarNum;
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
}
