import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static late SharedPreferences _prefs;

  static Future init(user) async {
    _prefs = await SharedPreferences.getInstance();
    var _email = _prefs.getString("email");
    if (_email != null) {
      user.id = _prefs.getInt("id");
      user.email = _prefs.getString("email");
      user.name = _prefs.getString("name");
      user.phone = _prefs.getString("phone");
      user.avatar = _prefs.getString("avatar");
      user.isLogedin = _prefs.getBool("isLogedin");
    }
  }

  static saveProfile(user) {
    if (user.id != null) _prefs.setInt("id", user.id);
    if (user.email != null) _prefs.setString("email", user.email);
    if (user.name != null) _prefs.setString("name", user.name);
    if (user.phone != null) _prefs.setString("phone", user.phone);
    if (user.avatar != null) _prefs.setString("avatar", user.avatar);
    if (user.isLogedin != null) _prefs.setBool("isLogedin", user.isLogedin);
  }
}
