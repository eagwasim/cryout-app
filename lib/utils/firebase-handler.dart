import 'dart:async';
import 'dart:io';

import 'package:cryout_app/utils/notification-handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FireBaseHandler {
  static const _USER_TOPIC_PREFIX = "channels.user.";
  static const _SAMARITAN_TOPIC_PREFIX = "channels.samaritan.";
  static const _DISTRESS_CHANNEL_TOPIC_PREFIX = "channels.distress.";
  static const _SAFE_WALK_CHANNEL_TOPIC = "channels.safe-walk.";

  static const IOS_BANNER_AD_UNIT_ID = 'ca-app-pub-6773273500391344/5319146497';
  static const ANDROID_BANNER_AD_UNIT_ID = 'ca-app-pub-6773273500391344/2853244187';
  static const ANDROID_NATIVE_AD_UNIT_ID = 'ca-app-pub-6773273500391344/8803333610';
  static const IOS_NATIVE_AD_UNIT_ID = 'ca-app-pub-6773273500391344/2976291867';
  static const ANDROID_AD_APP_ID = 'ca-app-pub-6773273500391344~9378048683';
  static const IOS_AD_APP_ID = 'ca-app-pub-6773273500391344~7298680250';

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  BuildContext context;

  FireBaseHandler(this.context);

  static FireBaseHandler instance;

  static FireBaseHandler of(BuildContext context) {
    if (instance == null) {
      instance = FireBaseHandler(context);
    }
    return instance;
  }

  static Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
    print("onBackground: $message");
    // NotificationHandler.handleInAppNotification(message, true);
  }

  static void configure() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        // NotificationHandler.handleInAppNotification(message, false);
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
    _firebaseMessaging.unsubscribeFromTopic(_SAMARITAN_TOPIC_PREFIX + "$userId");
  }

  static void subscribeToDistressChannelTopic(String channelId) {
    _firebaseMessaging.subscribeToTopic(_DISTRESS_CHANNEL_TOPIC_PREFIX + "$channelId");
  }

  static void unSubscribeToDistressChannelTopic(String channelId) {
    _firebaseMessaging.unsubscribeFromTopic(_DISTRESS_CHANNEL_TOPIC_PREFIX + "$channelId");
  }

  static void subscribeSafeWalkChannelTopic(String channelId) {
    _firebaseMessaging.subscribeToTopic(_SAFE_WALK_CHANNEL_TOPIC + "$channelId");
  }

  static void unSubscribeToSafeWalkChannelTopic(String channelId) {
    _firebaseMessaging.unsubscribeFromTopic(_SAFE_WALK_CHANNEL_TOPIC + "$channelId");
  }

  static void iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {});
  }

  static unsubscribeFromAllTopics() async {
    await _firebaseMessaging.deleteInstanceID();
    configure();
  }
}
