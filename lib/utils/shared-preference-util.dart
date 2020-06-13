import 'dart:convert';

import 'package:cryout_app/models/distress-call.dart';
import 'package:cryout_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceUtil {
  static const _CURRENT_USER_KEY = "CURRENT_USER_KEY";
  static const _USER_REFRESH_TOKEN = "USER_REFRESH_TOKEN";
  static const _CURRENT_PHONE_NUMBER_FOR_VERIFICATION = "CURRENT_PHONE_NUMBER_FOR_VERIFICATION";
  static const _USER_AUTHENTICATION_TOKEN = "USER_AUTHENTICATION_TOKEN";
  static const _CURRENT_DISTRESS_CALL = "CURRENT_DISTRESS_CALL";

  static Future<User> currentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final currentUser = prefs.getString(_CURRENT_USER_KEY) ?? null;

    if (currentUser == null) {
      return null;
    }
    return User.fromJson(jsonDecode(currentUser));
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      prefs.remove(_CURRENT_USER_KEY);
    } else {
      prefs.setString(_CURRENT_USER_KEY, jsonEncode(user.toJson()));
    }
  }

  static Future<String> getString(String key, String defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key) ?? defaultValue;
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  static Future<int> getInt(String key, int defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

  static Future<bool> getBool(String key, bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  static Future<void> savePhoneNumberForVerification(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_CURRENT_PHONE_NUMBER_FOR_VERIFICATION, phoneNumber);
  }

  static Future<String> getPhoneNumberForVerification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_CURRENT_PHONE_NUMBER_FOR_VERIFICATION);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_USER_AUTHENTICATION_TOKEN, token);
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_USER_REFRESH_TOKEN, refreshToken);
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_USER_AUTHENTICATION_TOKEN);
  }

  static Future<String> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_USER_REFRESH_TOKEN);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_CURRENT_USER_KEY);
    prefs.remove(_USER_AUTHENTICATION_TOKEN);
  }

  static Future<void> setCurrentDistressCall(DistressCall distressCall) async {
    final prefs = await SharedPreferences.getInstance();
    if (distressCall == null) {
      prefs.remove(_CURRENT_DISTRESS_CALL);
    } else {
      prefs.setString(_CURRENT_DISTRESS_CALL, jsonEncode(distressCall.toJson()));
    }
  }

  static Future<DistressCall> getCurrentDistressCall() async {
    final prefs = await SharedPreferences.getInstance();
    String dc = prefs.getString(_CURRENT_DISTRESS_CALL);

    if (dc == null) {
      return null;
    }

    return DistressCall.fromJSON(jsonDecode(dc));
  }
}
