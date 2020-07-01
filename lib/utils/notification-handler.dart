import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/distress-signal.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/recieved-safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/background_location_update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationHandler {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final Map<String, bool> _notificationChanelSubscription = {};

  static Future<void> initialize() async {
    var initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_alarm_1');
    var initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: _selectNotification);
  }

  static Future<void> handleInAppNotification(dynamic data, bool isAppLaunch) async {
    try {
      User user = await SharedPreferenceUtil.currentUser();

      if (user == null) {
        return;
      }

      var notificationData = Platform.isIOS ? data : data['data'];

      // Return is notification type isn't specified
      if (notificationData == null || !notificationData.containsKey('type')) {
        return;
      }

      if (notificationData['type'] == NOTIFICATION_TYPE_DISTRESS_SIGNAL_ALERT) {
        _handleNewDistressSignalNotification(notificationData, isAppLaunch);
      } else if (notificationData['type'] == NOTIFICATION_TYPE_DISTRESS_CHANNEL_MESSAGE) {
        _handleDistressChannelMessage(notificationData, isAppLaunch);
      } else if (notificationData['type'] == NOTIFICATION_TYPE_ACCOUNT_BLOCKED) {
        _handleAccountBlocked(isAppLaunch);
      } else if (notificationData['type'] == NOTIFICATION_TYPE_SAFE_WALK_START_NOTIFICATION) {
        _handleNewSafeWalkNotification(notificationData, isAppLaunch);
      } else if (notificationData['type'] == NOTIFICATION_TYPE_SAFE_WALK_CHANNEL_MESSAGE) {
        _handleSafeWalkChannelMessage(notificationData, isAppLaunch);
      }
    } catch (e) {
      print(e);
    }
  }

  static void _handleSafeWalkChannelMessage(data, bool isAppLaunch) async {
    User user = await SharedPreferenceUtil.currentUser();

    String senderUserId = data["senderUserId"];
    String safeWalkChannelId = data["safeWalkChannelId"];
    String safeWalkUserId = data["safeWalkUserId"];
    String senderName = data["senderName"];
    String message = data["message"];
    String messageType = data["messageType"];

    if (user.id == senderUserId) {
      return;
    }
    // Is Victim Channel
    if (user.id == safeWalkUserId) {
      var payload = {"route": Routes.SAFE_WALK_WALKER_SCREEN, "safeWalkID": safeWalkChannelId};

      if (!isAppLaunch || !_notificationChanelSubscription.containsKey(Routes.SAFE_WALK_WALKER_SCREEN + safeWalkChannelId)) {
        if (messageType == 'text') {
          _showMessageNotification(senderName, message, payload);
        } else if (messageType == 'img') {
          _showMessageNotificationWithImage(senderName, "Image", message, payload);
        }
      } else {
        _handleSafeWalkWalkerMessageNotificationClick(payload);
      }
    } else {
      var payload = {"route": Routes.SAFE_WALK_WATCHER_SCREEN, "safeWalkID": safeWalkChannelId};

      if (!isAppLaunch || !_notificationChanelSubscription.containsKey(Routes.SAFE_WALK_WATCHER_SCREEN + safeWalkChannelId)) {
        if (messageType == 'text') {
          _showMessageNotification(senderName, message, payload);
        } else if (messageType == 'img') {
          _showMessageNotificationWithImage(senderName, "Image", message, payload);
        }
      } else {
        _handleSafeWalkWatcherMessageNotificationClick(payload);
      }
    }
  }

  static void _handleNewSafeWalkNotification(notificationData, bool isAppLaunch) {
    if (!isAppLaunch) {
      var payload = {"route": Routes.RECEIVED_SAFE_WALK_LIST_SCREEN};
      _showDistressSignalNotification(
        notificationData['fullName'],
        'Watch me on the go. Dest: ${notificationData['destination']}',
        payload,
      );
    } else {
      _handleSafeWalkNotificationClick();
    }
  }

  static void subscribeRoute(String route) {
    _notificationChanelSubscription[route] = true;
  }

  static void unsubscribeRoute(String route) {
    _notificationChanelSubscription.remove(route);
  }

  static void _handleAccountBlocked(bool isAppLaunch) async {
    await SharedPreferenceUtil.clear();
    await FireBaseHandler.unsubscribeFromAllTopics();
    await ReceivedDistressSignalRepository.clear();
    await ReceivedSafeWalkRepository.clear();
    await BackgroundLocationUpdate.stopLocationTracking();

    locator<NavigationService>().pushNamedAndRemoveUntil(Routes.INTRODUCTION_SCREEN);

    if (!isAppLaunch) {
      _showGenericNotification('Account Suspended!', 'Your account would be unsuspended after a week');
    }
  }

  static Future<void> _handleDistressChannelMessage(dynamic data, bool isAppLaunch) async {
    User user = await SharedPreferenceUtil.currentUser();

    String senderUserId = data["senderUserId"];
    String distressChannelId = data["distressChannelId"];
    String distressUserId = data["distressUserId"];
    String senderName = data["senderName"];
    String message = data["message"];
    String messageType = data["messageType"];

    if (user.id == senderUserId) {
      return;
    }

    // If User Muted Distress Channel, Skip
    if (await SharedPreferenceUtil.getBool("${PreferenceConstants.DISTRESS_CHANNEL_MUTED}$distressChannelId", false)) {
      return;
    }

    // Is Victim Channel
    if (user.id == distressUserId) {
      var payload = {"route": Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, "distressChannelId": distressChannelId};

      if (!isAppLaunch || !_notificationChanelSubscription.containsKey(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN + distressChannelId)) {
        if (messageType == 'text') {
          _showMessageNotification(senderName, message, payload);
        } else if (messageType == 'img') {
          _showMessageNotificationWithImage(senderName, "Image", message, payload);
        }
      } else {
        _handleVictimDistressSignalMessageNotificationClick(payload);
      }
    } else {
      var payload = {"route": Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN, "distressChannelId": distressChannelId};

      if (!isAppLaunch || !_notificationChanelSubscription.containsKey(Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN + distressChannelId)) {
        if (messageType == 'text') {
          _showMessageNotification(senderName, message, payload);
        } else if (messageType == 'img') {
          _showMessageNotificationWithImage(senderName, "Image", message, payload);
        }
      } else {
        _handleSamaritanDistressSignalMessageNotificationClick(payload);
      }
    }
  }

  static Future<void> _handleNewDistressSignalNotification(dynamic data, bool isAppLaunch) async {
    ReceivedDistressSignal receivedDistressSignal = ReceivedDistressSignal.fromJSON(data);

    if (!isAppLaunch) {
      var payload = {"route": Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN};
      _showDistressSignalNotification(
        'Distress Signal: ${receivedDistressSignal.detail}',
        '${receivedDistressSignal.firstName} broadcast a distress signal ${receivedDistressSignal.distance == null ? "" : receivedDistressSignal.distance + "km near you"}',
        payload,
      );
    } else {
      _handleDistressSignalNotificationClick();
    }
  }

  static Future<void> _selectNotification(String payload) async {
    if (payload == null) {
      return;
    }

    var payloadData = jsonDecode(payload);

    if (payloadData['route'] == Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN) {
      _handleDistressSignalNotificationClick();
    } else if (payloadData['route'] == Routes.VICTIM_DISTRESS_CHANNEL_SCREEN) {
      _handleVictimDistressSignalMessageNotificationClick(payloadData);
    } else if (payloadData['route'] == Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN) {
      _handleSamaritanDistressSignalMessageNotificationClick(payloadData);
    } else if (payloadData['route'] == Routes.RECEIVED_SAFE_WALK_LIST_SCREEN) {
      _handleSafeWalkNotificationClick();
    } else if (payloadData['route'] == Routes.SAFE_WALK_WALKER_SCREEN) {
      _handleSafeWalkWalkerMessageNotificationClick(payloadData);
    } else if (payloadData['route'] == Routes.SAFE_WALK_WATCHER_SCREEN) {
      _handleSafeWalkWatcherMessageNotificationClick(payloadData);
    }
  }

  static Future<void> _handleVictimDistressSignalMessageNotificationClick(dynamic data) async {
    var user = await SharedPreferenceUtil.currentUser();

    var userPreferenceDatabaseReference = database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference();
    var dbSS = await userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).once();

    var currentDistressCall = (dbSS == null || dbSS.value == null) ? null : DistressSignal.fromJSON(dbSS.value);

    // Not the current distress call so skip notification
    if (currentDistressCall == null || "${currentDistressCall.id}" != data['distressChannelId']) {
      return;
    }
    locator<NavigationService>().pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: currentDistressCall);
  }

  static Future<void> _handleSamaritanDistressSignalMessageNotificationClick(dynamic data) async {
    locator<NavigationService>().pushNamed(Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN, arguments: data["distressChannelId"]);
  }

  static Future<void> _handleSafeWalkWatcherMessageNotificationClick(dynamic data) async {
    locator<NavigationService>().pushNamed(Routes.SAFE_WALK_WATCHER_SCREEN, arguments: data["safeWalkID"]);
  }

  static Future<void> _handleSafeWalkWalkerMessageNotificationClick(dynamic data) async {
    locator<NavigationService>().pushNamed(Routes.SAFE_WALK_WALKER_SCREEN);
  }

  static Future<void> _handleDistressSignalNotificationClick() async {
    locator<NavigationService>().pushNamed(Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN);
  }

  static Future<void> _handleSafeWalkNotificationClick() async {
    locator<NavigationService>().pushNamed(Routes.RECEIVED_SAFE_WALK_LIST_SCREEN);
  }

  static Future<void> _onDidReceiveLocalNotification(int id, String title, String body, String payload) async {
    print("ID: $id, Title: $title, body: $body, Payload: $payload");
  }

  static Future<void> _showGenericNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      GENERIC_NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_APP_NAME,
      GENERIC_NOTIFICATION_CHANNEL_NAME,
      importance: Importance.Default,
      priority: Priority.Default,
      ticker: 'ticker',
      icon: "ic_stat_alarm_1",
      playSound: true,
      sound: RawResourceAndroidNotificationSound(GENERIC_NOTIFICATION_ALERT_SOUND),
      color: Colors.blue,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: '$GENERIC_NOTIFICATION_ALERT_SOUND.m4r');
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: null);
  }

  static Future<void> _showMessageNotification(String title, String body, dynamic payload) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      DISTRESS_SIGNAL_MESSAGE_NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_APP_NAME,
      DISTRESS_SIGNAL_MESSAGE_NOTIFICATION_CHANNEL_NAME,
      importance: Importance.Default,
      priority: Priority.Default,
      ticker: 'ticker',
      icon: "ic_stat_message_notification_icon",
      playSound: true,
      sound: RawResourceAndroidNotificationSound(GENERIC_NOTIFICATION_ALERT_SOUND),
      color: Colors.blue,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: '$GENERIC_NOTIFICATION_ALERT_SOUND.m4r');
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: jsonEncode(payload));
  }

  static Future<void> _showMessageNotificationWithImage(String title, String body, String imageUrl, dynamic payload) async {
    var bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture-${DateTime.now().millisecondsSinceEpoch}');
    var bigPictureStyle = BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath));

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      DISTRESS_SIGNAL_MESSAGE_NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_APP_NAME,
      DISTRESS_SIGNAL_MESSAGE_NOTIFICATION_CHANNEL_NAME,
      importance: Importance.Default,
      priority: Priority.Default,
      ticker: 'ticker',
      icon: "ic_stat_message_notification_icon",
      playSound: true,
      styleInformation: bigPictureStyle,
      sound: RawResourceAndroidNotificationSound(GENERIC_NOTIFICATION_ALERT_SOUND),
      color: Colors.blue,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: '$GENERIC_NOTIFICATION_ALERT_SOUND.m4r');
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: jsonEncode(payload));
  }

  static Future<void> _showDistressSignalNotification(String title, String body, dynamic payload) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      DISTRESS_SIGNAL_NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_APP_NAME,
      DISTRESS_SIGNAL_NOTIFICATION_CHANNEL_NAME,
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'ticker',
      icon: "ic_stat_alarm_1",
      playSound: true,
      sound: RawResourceAndroidNotificationSound(DISTRESS_SIGNAL_ALERT_SOUND),
      color: Colors.deepOrange,
      vibrationPattern: Int64List.fromList([0, 100]),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: '$DISTRESS_SIGNAL_ALERT_SOUND.m4r', presentSound: true);
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: jsonEncode(payload));
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(url);
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static const String NOTIFICATION_APP_NAME = 'Cry Out';

  static const String DISTRESS_SIGNAL_NOTIFICATION_CHANNEL_NAME = 'Cry Out: Distress Signal';
  static const String DISTRESS_SIGNAL_NOTIFICATION_CHANNEL_ID = '1';
  static const String DISTRESS_SIGNAL_ALERT_SOUND = 'serious_strike';

  static const String DISTRESS_SIGNAL_MESSAGE_NOTIFICATION_CHANNEL_NAME = 'Cry Out: Distress Signal Message';
  static const String DISTRESS_SIGNAL_MESSAGE_NOTIFICATION_CHANNEL_ID = '3';
  static const String DISTRESS_SIGNAL_MESSAGE_ALERT_SOUND = 'juntos';

  static const String GENERIC_NOTIFICATION_CHANNEL_NAME = 'Cry Out: Generic Notification';
  static const String GENERIC_NOTIFICATION_CHANNEL_ID = '2';
  static const String GENERIC_NOTIFICATION_ALERT_SOUND = 'juntos';

  static const String NOTIFICATION_TYPE_DISTRESS_SIGNAL_ALERT = 'DISTRESS_SIGNAL_ALERT';
  static const String NOTIFICATION_TYPE_DISTRESS_CHANNEL_MESSAGE = 'DISTRESS_CHANNEL_MESSAGE';
  static const String NOTIFICATION_TYPE_ACCOUNT_BLOCKED = 'ACCOUNT_BLOCKED';
  static const String NOTIFICATION_TYPE_SAFE_WALK_START_NOTIFICATION = 'SAFE_WALK_START_NOTIFICATION';
  static const String NOTIFICATION_TYPE_SAFE_WALK_CHANNEL_MESSAGE = 'SAFE_WALK_CHANNEL_MESSAGE';
}
