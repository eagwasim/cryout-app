import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class BackgroundLocationUpdate {
  static setUpLocationTracking(BuildContext _buildContext) {
    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) async {
      if (await SharedPreferenceUtil.isSafeWalking()) {
        SafeWalk safeWalk = await SharedPreferenceUtil.getCurrentSafeWalk();
        SharedPreferenceUtil.updateUserLastKnownSafeWalkLocation("${safeWalk.id}", location.coords.latitude, location.coords.longitude);
      }

      User user = await SharedPreferenceUtil.currentUser();

      var dbSS = await database.reference().child('users').reference().child("${user.id}").reference().child("preferences").reference().child(PreferenceConstants.SAMARITAN_MODE_ENABLED).once();
      bool _samaritan = dbSS == null || dbSS.value == null ? false : dbSS.value;

      if (_samaritan) {
        SamaritanResource.updateSamaritanLocation(_buildContext, {'lat': location.coords.latitude, 'lon': location.coords.longitude});
      }
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_NAVIGATION,
        distanceFilter: 5,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: false,
        allowIdenticalLocations: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        notification: bg.Notification(
          smallIcon: "drawable/ic_stat_alarm_1",
          color: "#00b0ff",
          title: "Cry Out",
          text: "Cry Out is active",
          priority: 0,
          channelName: "cry-out-background-channel",
        ),
      ),
    );
  }

  static Future stopLocationTracking() async {
    await bg.BackgroundGeolocation.stop();
  }

  static void startLocationTracking() async {
    try {
      await bg.BackgroundGeolocation.start();
    } catch (e) {}
  }
}
