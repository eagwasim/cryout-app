import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/distress-call.dart';
import 'package:cryout_app/models/notification.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
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

  static Future<void> initialize() async {
    var initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_alarm_1');
    var initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: _selectNotification);
  }

  static Future<void> handleInAppNotification(dynamic data) async {
    User user = await SharedPreferenceUtil.currentUser();

    if (user == null) {
      return;
    }
    // We would only send a notification or data but not both.
    if (data.containsKey('notification') && data['notification'].containsKey('title') && data['notification']['title'] != '' && data['notification']['title'] != null) {
      _showGenericNotification(data['notification']['title'], data['notification']['body']);
      return;
    }

    // Return is notification type isn't specified
    if (!data.containsKey('data') || !data['data'].containsKey('type')) {
      return;
    }

    if (data['data']['type'] == NOTIFICATION_TYPE_DISTRESS_SIGNAL_ALERT) {
      _handleNewDistressSignalNotification(data['data']);
    } else if (data['data']['type'] == NOTIFICATION_TYPE_DISTRESS_CHANNEL_MESSAGE) {
      _handleDistressChannelMessage(data['data']);
    } else if (data['data']['type'] == NOTIFICATION_TYPE_ACCOUNT_BLOCKED) {
      _handleAccountBlocked();
    }
  }

  static void _handleAccountBlocked() async {
    await SharedPreferenceUtil.clear();
    await FireBaseHandler.unsubscribeFromAllTopics();
    await NotificationRepository.clear();
    await BackgroundLocationUpdate.stopLocationTracking();
    locator<NavigationService>().pushNamedAndRemoveUntil(Routes.INTRODUCTION_SCREEN);

    _showGenericNotification('Account Suspended!', 'Your account would be unsuspended after a week');
  }

  static Future<void> _handleDistressChannelMessage(dynamic data) async {
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

      if (messageType == 'text') {
        _showMessageNotification(senderName, message, payload);
      } else if (messageType == 'img') {
        _showMessageNotificationWithImage(senderName, "Image", message, payload);
      }
    } else {
      var notificationId = "$distressUserId-$distressChannelId";

      if (await NotificationRepository.getById(notificationId) == null) {
        print("NOTIFICATION NOT FOUND");
        return;
      }
      var payload = {"route": Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN, "notificationId": notificationId};

      if (messageType == 'text') {
        _showMessageNotification(senderName, message, payload);
      } else if (messageType == 'img') {
        _showMessageNotificationWithImage(senderName, "Image", message, payload);
      }
    }
  }

  static Future<void> _handleNewDistressSignalNotification(dynamic data) async {
    String notificationType = data["type"];
    String notificationId = data["id"];

    ReceivedDistressSignal receivedDistressSignal = ReceivedDistressSignal.fromJSON(data);

    InAppNotification notification = InAppNotification(
      notificationId: notificationId,
      notificationType: notificationType,
      dateCreated: DateTime.now().millisecondsSinceEpoch,
      notificationData: jsonEncode(receivedDistressSignal.toJSON()),
      opened: 0,
    );

    await NotificationRepository.save(notification);

    var payload = {"route": Routes.NOTIFICATIONS_SCREEN};

    _showDistressSignalNotification(
      'Distress Signal: ${receivedDistressSignal.detail}',
      '${receivedDistressSignal.firstName} broadcast a distress signal ${receivedDistressSignal.distance == null ? "" : receivedDistressSignal.distance + "km near you"}',
      payload,
    );
  }

  static Future<void> _selectNotification(String payload) async {
    if (payload == null) {
      return;
    }

    var payloadData = jsonDecode(payload);

    if (payloadData['route'] == Routes.NOTIFICATIONS_SCREEN) {
      _handleDistressSignalNotificationClick();
    } else if (payloadData['route'] == Routes.VICTIM_DISTRESS_CHANNEL_SCREEN) {
      _handleVictimDistressSignalMessageNotificationClick(payloadData);
    } else if (payloadData['route'] == Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN) {
      _handleSamaritanDistressSignalMessageNotificationClick(payloadData);
    }
  }

  static Future<void> _handleVictimDistressSignalMessageNotificationClick(dynamic data) async {
    var user = await SharedPreferenceUtil.currentUser();

    var userPreferenceDatabaseReference = database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference();
    var dbSS = await userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).once();

    var currentDistressCall = (dbSS == null || dbSS.value == null) ? null : DistressCall.fromJSON(dbSS.value);

    // Not the current distress call so skip notification
    if ("${currentDistressCall.id}" != data['route']) {
      return;
    }
    // Future.delayed(Duration(seconds: 1), () {
    locator<NavigationService>().pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: currentDistressCall);
    // });
  }

  static Future<void> _handleSamaritanDistressSignalMessageNotificationClick(dynamic data) async {
    InAppNotification inAppNotification = await NotificationRepository.getById(data['notificationId']);

    if (inAppNotification == null) {
      return;
    }
    locator<NavigationService>().pushNamed(Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN, arguments: ReceivedDistressSignal.fromJSON(jsonDecode(inAppNotification.notificationData)));
  }

  static Future<void> _handleDistressSignalNotificationClick() async {
    //  Future.delayed(Duration(seconds: 1), () {
    locator<NavigationService>().navigateTo(Routes.NOTIFICATIONS_SCREEN);
    //});
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
}
