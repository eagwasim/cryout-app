import 'dart:convert';

import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/distress-signal.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/received-safe-walk.dart';
import 'package:cryout_app/models/safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceUtil {
  static const _CURRENT_USER_KEY = "CURRENT_USER_KEY";
  static const _USER_REFRESH_TOKEN = "USER_REFRESH_TOKEN";
  static const _CURRENT_PHONE_NUMBER_FOR_VERIFICATION = "CURRENT_PHONE_NUMBER_FOR_VERIFICATION";
  static const _USER_AUTHENTICATION_TOKEN = "USER_AUTHENTICATION_TOKEN";
  static const _CACHED_RECEIVED_DISTRESS_CALL = "CACHED_DISTRESS_CALL_";
  static const _CACHED_RECEIVED_SAFE_WALK = "CACHED_SAFE_WALK_";
  static const _TOPICS = "REGISTERED_TOPICS_KEY";
  static const _IS_SAFE_WALKING = "IS_SAFE_WALKING";

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
    if (value == null) {
      prefs.remove(key);
    } else {
      prefs.setBool(key, value);
    }
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

  static Future<void> setSafeWalk(SafeWalk safeWalk) async {
    User user = await currentUser();

    DatabaseReference _dbPreference = database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference();
    if (safeWalk == null) {
      _dbPreference.child(PreferenceConstants.CURRENT_SAFE_WALK).remove();
    } else {
      _dbPreference.child(PreferenceConstants.CURRENT_SAFE_WALK).set(safeWalk.toJson());
    }
  }

  static Future<SafeWalk> getCurrentSafeWalk() async {
    User user = await currentUser();

    DatabaseReference _dbPreference = database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference();
    var dbSS = await _dbPreference.child(PreferenceConstants.CURRENT_SAFE_WALK).once();
    dynamic sw = dbSS == null || dbSS.value == null ? null : dbSS.value;

    if (sw == null) {
      return null;
    }

    return SafeWalk.fromJSON(sw);
  }

  static Future<void> setCurrentDistressCall(DistressSignal distressCall) async {
    User user = await currentUser();

    DatabaseReference _dbPreference = database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference();

    if (distressCall == null) {
      _dbPreference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).remove();
    } else {
      _dbPreference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).set(distressCall.toJson());
    }
  }

  static Future<DistressSignal> getCurrentDistressCall() async {
    User user = await currentUser();

    DatabaseReference _dbPreference = database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference();
    var dbSS = await _dbPreference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).once();
    dynamic sw = dbSS == null || dbSS.value == null ? null : dbSS.value;

    if (sw == null) {
      return null;
    }

    return DistressSignal.fromJSON(sw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<ReceivedDistressSignal> getCachedDistressCall(String distressCallId) async {
    final prefs = await SharedPreferences.getInstance();
    String dc = prefs.getString("$_CACHED_RECEIVED_DISTRESS_CALL.$distressCallId");

    if (dc == null) {
      return null;
    }

    return ReceivedDistressSignal.fromJSON(jsonDecode(dc));
  }

  static Future<void> saveCachedDistressCall(ReceivedDistressSignal receivedDistressSignal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("$_CACHED_RECEIVED_DISTRESS_CALL.${receivedDistressSignal.distressId}", jsonEncode(receivedDistressSignal.toJSON()));
  }

  static Future<ReceivedSafeWalk> getCachedSafeWalkCall(String id) async {
    final prefs = await SharedPreferences.getInstance();
    String dc = prefs.getString("$_CACHED_RECEIVED_SAFE_WALK.$id");

    if (dc == null) {
      return null;
    }

    return ReceivedSafeWalk.fromJSON(jsonDecode(dc));
  }

  static Future<void> saveCachedSafeWalkCall(ReceivedSafeWalk safeWalk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("$_CACHED_RECEIVED_SAFE_WALK.${safeWalk.safeWalkId}", jsonEncode(safeWalk.toJSON()));
  }

  static Future<void> addToRegisteredTopic(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> topicList = prefs.getStringList(_TOPICS);
    if (topicList == null) {
      topicList = new List();
    }

    topicList.add(topicId);
    prefs.setStringList(_TOPICS, topicList);
  }

  static Future<void> removeFromTopicList(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> topicList = prefs.getStringList(_TOPICS);
    if (topicList == null) {
      topicList = new List();
    }

    topicList.removeWhere((e) {
      return topicId == e;
    });
    prefs.setStringList(_TOPICS, topicList);
  }

  static Future<List<String>> getSubScribedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> topicList = prefs.getStringList(_TOPICS);

    if (topicList == null) {
      topicList = new List();
    }
    return topicList;
  }

  static void startedSafeWalk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_IS_SAFE_WALKING, true);
  }

  static void endSafeWalk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_IS_SAFE_WALKING);
  }

  static Future<bool> isSafeWalking() async {
    final prefs = await SharedPreferences.getInstance();
    bool isSafeWalking = prefs.getBool(_IS_SAFE_WALKING);
    return isSafeWalking == null ? false : isSafeWalking;
  }

  static Future<void> updateUserLastKnownSafeWalkLocation(String safeWalkId, double lat, double lon) async {
    DatabaseReference _dbPreference = database.reference().child('safe_walk_locations').reference().child("$safeWalkId").reference();
    await _dbPreference.set({"lat": lat, "lon": lon});
  }
}
