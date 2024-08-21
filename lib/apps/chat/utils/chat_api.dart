import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import './constants.dart';

class ChatAPI {
  final dio = Dio();

  /**
   * upload file to backend
   */
  Future<User?> UserInfo(user_id) async {
    try {
      var url = "${USER_URL}/${user_id}/info";
      var response = await dio.post(url);
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (error) {
      debugPrint('UserInfo error: $error');
    }
    return null;
  }

  Future<Map> get_creds() async {
    var res = {};
    try {
      var url = USER_URL + "/23" + "/oss_credentials";
      var response = await dio.post(url);
      res = response.data["credentials"];
    } catch (e) {
      debugPrint("get_creds error: $e");
      return {};
    }
    return res;
  }
}
