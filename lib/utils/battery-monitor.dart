import 'dart:async';

import 'package:battery/battery.dart';

class DeviceInformationService {
  bool _broadcastBattery = false;
  Battery _battery = Battery();

  Stream<BatteryInformation> get batteryLevel => _batteryLevelController.stream;
  StreamController<BatteryInformation> _batteryLevelController = StreamController<BatteryInformation>();

  void stopBroadcast() {
    _broadcastBattery = false;
  }

  Future broadcastBatteryLevel() async {
    _broadcastBattery = true;
    while (_broadcastBattery) {
      var batteryLevel = await _battery.batteryLevel;
      _batteryLevelController.add(BatteryInformation(batteryLevel));
      await Future.delayed(Duration(seconds: 5));
    }
  }
}

class BatteryInformation {
  final int batteryLevel;
  BatteryInformation(this.batteryLevel);
}
