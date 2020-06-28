import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class BackgroundLocationUpdate {
  static setUpLocationTracking(BuildContext _buildContext) {
    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
      SamaritanResource.updateSamaritanLocation(_buildContext, {'lat': location.coords.latitude, 'lon': location.coords.longitude});
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 1.0,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: false,
        allowIdenticalLocations: false,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        notification: bg.Notification(
          smallIcon: "drawable/ic_stat_alarm_1",
          color: "#00b0ff",
          title: "",
          text: "You have samaritan mode or safe walk active",
        ),
      ),
    );
  }

  static Future stopLocationTracking() async {
    await bg.BackgroundGeolocation.stop();
  }

  static void startLocationTracking() {
    bg.BackgroundGeolocation.start();
  }

}
