import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/login/data/user_model.dart';


final log = Logger("SharedPreferencesHelper");

class SharedPreferencesHelper {
  static final String _keyUserData = 'user_data';

  static UserModel? currentUser;

  // controle de missão


  static Future<void> saveOrUpdateUserData(UserModel user) async {
    final sharedPreference = await SharedPreferences.getInstance();
    currentUser = user;

    await sharedPreference.setString(_keyUserData, json.encode(user.toJson()));
  }


  static Future<UserModel?> loadUserData() async {
    final sharedPreference = await SharedPreferences.getInstance();
    final userData = sharedPreference.getString(_keyUserData);

    if (userData != null) {
      Map<String, dynamic> userMap = Map.from(json.decode(userData));

      currentUser = UserModel.fromJson(userMap);
      return currentUser;
    }

    return null;
  }


  static Future<void> clearUserData() async {
    final sharedPreference = await SharedPreferences.getInstance();
    await sharedPreference.remove(_keyUserData);
    currentUser = null;
  }
}
