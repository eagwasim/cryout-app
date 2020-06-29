import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';

class Routes {
  static const INTRODUCTION_SCREEN = '/introduction-screen';
  static const HOME_SCREEN = '/home-screen';
  static const BASE_SCREEN = '/base-screen';
  static const PHONE_CONFIRMATION_SCREEN = '/phone-confirmation-screen';
  static const PHONE_VERIFICATION_SCREEN = '/phone-verification-screen';
  static const SPLASH_SCREEN = '/splash-screen';
  static const USER_PROFILE_UPDATE_SCREEN = '/user-profile-update-screen';
  static const USER_PROFILE_PHOTO_UPDATE_SCREEN = '/user-profile-photo-update-screen';
  static const DISTRESS_CATEGORY_SELECTION_SCREEN = "/distress-category-selection";
  static const VICTIM_DISTRESS_CHANNEL_SCREEN = "/victim-distress-channel-screen";
  static const RECEIVED_DISTRESS_SIGNAL_SCREEN = "/distress-signal-list-screen";
  static const SAMARITAN_DISTRESS_CHANNEL_SCREEN = "/samaritan-distress-channel-screen";
  static const VIEW_DISTRESS_LOCATION_ON_MAP_SCREEN = "/view-distress-location-on-map-screen";
  static const STATIC_WEB_PAGE_VIEW_SCREEN = "/static-web-page-screen";
  static const MANAGE_EMERGENCY_CONTACTS_SCREEN = "/manage-emergency-contacts";
  static const START_SAFE_WALK_SCREEN = "/start-safe-walk-screen";
  static const SAFE_WALK_WALKER_SCREEN = "/safe-walk-walker-screen";
  static const SAFE_WALK_WATCHER_SCREEN = "/safe-walk-watcher-screen";

  static Future<String> initialRoute() async {
    User user = await SharedPreferenceUtil.currentUser();

    if (user == null) {
      return INTRODUCTION_SCREEN;
    } else if (user.firstName == "" || user.lastName == "" || user.emailAddress == "" || user.gender == "") {
      return USER_PROFILE_UPDATE_SCREEN;
    } else if (user.profilePhoto == "") {
      return USER_PROFILE_PHOTO_UPDATE_SCREEN;
    } else {
      return BASE_SCREEN;
    }
  }
}
