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
  double? _credit;
  bool _signUP = false;
  int _updated_at = 0;

  User({
    bool? isLogedin,
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? avatar_bot,
    double? credit,
    bool? signUP = true,
    int? updated_at = 0,
  })  : _isLogedin = isLogedin ?? false,
        _id = id ?? 0,
        _name = name,
        _email = email,
        _phone = phone,
        _avatar = avatar,
        _avatar_bot = avatar_bot,
        _credit = credit,
        _signUP = signUP ?? false,
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

  double? get credit => _credit;
  set credit(double? recharge) {
    _credit = recharge;
  }

  void reset() {
    _isLogedin = false;
  }

  Map<String, dynamic> toJson() => {
        'id': _id,
        'name': _name,
        "email": _email,
        "phone": _phone,
        "avatar": _avatar,
        "avatar_bot": _avatar_bot,
        "credit": _credit,
        "isLogedin": _isLogedin,
        "updated_at": _updated_at,
      };

  static User fromJson(u) {
    return User(
      id: u["id"] as int,
      name: u["name"],
      email: u["email"],
      phone: u["phone"],
      avatar: u["avatar"],
      avatar_bot: u["avatar_bot"],
      credit: u["credit"],
      updated_at: u["updated_at"] as int,
      isLogedin: u["isLogedin"] ?? false,
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
    double? credit,
    bool? signUP,
    int? updated_at,
  }) {
    if (isLogedin != null) _isLogedin = isLogedin;
    if (id != null) _id = id;
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (avatar != null) _avatar = avatar;
    if (avatar_bot != null) _avatar_bot = avatar_bot;
    if (credit != null) _credit = credit;
    if (signUP != null) _signUP = signUP;
    if (updated_at != null) _updated_at = updated_at;
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
    if (u.credit != null) _credit = u.credit;
    notifyListeners();
  }
}
