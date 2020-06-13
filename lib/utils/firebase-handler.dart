import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryout_app/models/notification.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FireBaseHandler {
  static const _USER_TOPIC_PREFIX = "channels.user.";
  static const _SAMARITAN_TOPIC_PREFIX = "channels.samaritan.";

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
    if (message.containsKey('data')) {
      // Handle data message
      final dynamic data = message['data'];
      print("BackGround Message:");
      print(data);
      _logNotification(message["data"]);
    }

    if (message.containsKey('notification')) {
      // Handle notification message
      final dynamic notification = message['notification'];
      print("BackGround Notification:");
      print(notification);
      _showNotification(message["notification"], false);
    }

    return null;
  }

  static void configure() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        if (message.containsKey('data')) {
          _logNotification(message["data"]);
        }
        if (message.containsKey('notification')) {
          _showNotification(message["notification"], false);
        }
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
  }

  static Future<void> _logNotification(dynamic data) async {
    if (data == null) {
      return;
    }

    String notificationType = data["type"];
    String notificationId = data["id"];

    if (notificationType == "DISTRESS_SIGNAL_ALERT") {
      ReceivedDistressSignal receivedDistressSignal = ReceivedDistressSignal.fromJSON(data);

      InAppNotification notification = InAppNotification(
          notificationId: notificationId,
          notificationType: notificationType,
          dateCreated: DateTime.now().millisecondsSinceEpoch,
          notificationData: jsonEncode(receivedDistressSignal.toJSON()),
          opened: 0);

      await NotificationRepository.save(notification);

      await _showNotification({
        "title": "Distress Signal: " + receivedDistressSignal.detail,
        //"image": receivedDistressSignal.photo,
        "body": "${receivedDistressSignal.firstName} broadcast a distress signal ${receivedDistressSignal.distance == null ? "" : receivedDistressSignal.distance + "km near you"}",
      }, true);
    }
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(url);
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> _showNotification(dynamic data, bool playSound) async {
    if (data == null) {
      return;
    }
    var bigPictureStyle;

    if (data.containsKey("image")) {
      var bigPicturePath = await _downloadAndSaveFile(data["image"], 'bigPicture');
      bigPictureStyle = BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath));
    }
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '10101010101',
      'Cry Out',
      'Cry Out Notification Channel',
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'ticker',
      icon: "ic_stat_alarm_1",
      playSound: playSound,
      sound: playSound ? RawResourceAndroidNotificationSound('serious_strike') : null,
      color: Colors.deepOrange,
      styleInformation: bigPictureStyle,
      vibrationPattern: Int64List.fromList([1000, 5000, 6000, 1000, 5000, 6000]),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: 'serious-strike.m4r');
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, data['title'], data['body'], platformChannelSpecifics,
        payload: jsonEncode({"click_action": "FLUTTER_NOTIFICATION_CLICK", "status": Routes.NOTIFICATIONS_SCREEN}));
  }

  static void requestPermission() {
    if (Platform.isIOS) {
      iOSPermission();
    }
  }

  static void subscribeToUserTopic(String userId) {
    _firebaseMessaging.subscribeToTopic(_USER_TOPIC_PREFIX + "$userId");
  }

  static void unSubscribeToUserTopic(String userId) {
    _firebaseMessaging.unsubscribeFromTopic(_USER_TOPIC_PREFIX + "$userId");
  }

  static void subscribeToSamaritanTopic(String userId) {
    _firebaseMessaging.subscribeToTopic(_SAMARITAN_TOPIC_PREFIX + "$userId");
  }

  static void unSubscribeToSamaritanTopic(String userId) {
    _firebaseMessaging.subscribeToTopic(_SAMARITAN_TOPIC_PREFIX + "$userId");
  }

  static void iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {});
  }
}
