import 'dart:async';
import 'dart:convert';

import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

class NotificationInfo {
  int activeDistressCallCount;
  int activeSafeWalkCount;

  NotificationInfo(this.activeDistressCallCount, this.activeSafeWalkCount);
}

class WebNotificationService {
  bool _broadcast = false;
  BuildContext _buildContext;

  Stream<NotificationInfo> get counts => _controller.stream;
  StreamController<NotificationInfo> _controller = StreamController<NotificationInfo>();

  WebNotificationService(this._buildContext);

  void stopBroadcast() {
    _broadcast = false;
  }

  bool isBroadcast() {
    return _broadcast;
  }

  void startBroadCast() async {
    _broadcast = true;
    while (_broadcast) {
      int activeSafeWalksCount = 0;
      int activeDistressCallCount = 0;

      Response response = await SamaritanResource.activeSafeWalksCount(_buildContext);

      if (response.statusCode != 200) {
        await Future.delayed(Duration(seconds: 10));
        continue;
      }

      activeSafeWalksCount = jsonDecode(response.body)['data'];

      response = await SamaritanResource.activeDistressCallsCount(_buildContext);

      if (response.statusCode != 200) {
        await Future.delayed(Duration(seconds: 10));
        continue;
      }

      activeDistressCallCount = jsonDecode(response.body)['data'];

      _controller.add(NotificationInfo(activeDistressCallCount, activeSafeWalksCount));

      await Future.delayed(Duration(seconds: 10));
    }
  }
}
