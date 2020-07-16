import 'package:cryout_app/models/distress-signal.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/screens/distress-category-selection-screen.dart';
import 'package:cryout_app/screens/emergency-contacts-management-screen.dart';
import 'package:cryout_app/screens/home-screen.dart';
import 'package:cryout_app/screens/introduction-screen.dart';
import 'package:cryout_app/screens/phone-confirmation-firebase-screen.dart';
import 'package:cryout_app/screens/phone-confirmation-screen.dart';
import 'package:cryout_app/screens/phone-verification-screen.dart';
import 'package:cryout_app/screens/received-distress-signal-list-screen.dart';
import 'package:cryout_app/screens/received-safe-walk-list-screen.dart';
import 'package:cryout_app/screens/safe-walk-walker-screen.dart';
import 'package:cryout_app/screens/safe-walk-watcher-screen.dart';
import 'package:cryout_app/screens/safewalk-creation-screen.dart';
import 'package:cryout_app/screens/samaritan-distress-channel-screen.dart';
import 'package:cryout_app/screens/splash-screen.dart';
import 'package:cryout_app/screens/static-page-screen.dart';
import 'package:cryout_app/screens/user-profile-picture-update-screen.dart';
import 'package:cryout_app/screens/user-profile-update-screen.dart';
import 'package:cryout_app/screens/victim-distress-channel-screen.dart';
import 'package:cryout_app/screens/view-distress-location-on-map-scree.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState.pushNamed(routeName);
  }

  void goBack() {
    return navigatorKey.currentState.pop();
  }

  Future<dynamic> pushNamed(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState.pushNamed(routeName, arguments: arguments);
  }

  void pop({dynamic result}) {
    navigatorKey.currentState.pop(result);
  }

  Future<dynamic> popAndPushNamed(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState.popAndPushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacementNamed(String routeName) {
    return navigatorKey.currentState.pushReplacementNamed(routeName);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName) {
    return navigatorKey.currentState.pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false);
  }

  Future<dynamic> pushNamedAndRemoveInstance(String routeName) {
    return navigatorKey.currentState.pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => route.settings.name == routeName);
  }
}

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => NavigationService());
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.INTRODUCTION_SCREEN:
      return MaterialPageRoute(builder: (context) => AppIntroductionScreen());
    case Routes.HOME_SCREEN:
      return MaterialPageRoute(builder: (context) => HomeScreen());
    case Routes.SPLASH_SCREEN:
      return MaterialPageRoute(builder: (context) => SplashScreen());
    case Routes.PHONE_VERIFICATION_SCREEN:
      return MaterialPageRoute(builder: (context) => PhoneVerificationScreen());
    case Routes.PHONE_CONFIRMATION_SCREEN:
      return MaterialPageRoute(builder: (context) => PhoneConfirmationScreen());
    case Routes.USER_PROFILE_UPDATE_SCREEN:
      return MaterialPageRoute(builder: (context) => UserProfileUpdateScreen());
    case Routes.USER_PROFILE_PHOTO_UPDATE_SCREEN:
      return MaterialPageRoute(builder: (context) => UserProfilePictureUpdateScreen());
    case Routes.DISTRESS_CATEGORY_SELECTION_SCREEN:
      return MaterialPageRoute(builder: (context) => DistressCategorySelectionScreen());
    case Routes.VICTIM_DISTRESS_CHANNEL_SCREEN:
      var argument = settings.arguments as DistressSignal;
      return MaterialPageRoute(builder: (context) => VictimDistressChannelScreen(distressCall: argument));
    case Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN:
      return MaterialPageRoute(builder: (context) => ReceivedDistressSignalListScreen());
    case Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN:
      var argument = settings.arguments as String;
      return MaterialPageRoute(builder: (context) => SamaritanDistressChannelScreen(receivedDistressSignalId: argument));
    case Routes.VIEW_DISTRESS_LOCATION_ON_MAP_SCREEN:
      var argument = settings.arguments as ReceivedDistressSignal;
      return MaterialPageRoute(builder: (context) => ViewDistressLocationOnMapScreen(distressSignal: argument));
    case Routes.STATIC_WEB_PAGE_VIEW_SCREEN:
      var argument = settings.arguments as WebPageModel;
      return MaterialPageRoute(builder: (context) => StaticPageScreen(webPageModel: argument));
    case Routes.MANAGE_EMERGENCY_CONTACTS_SCREEN:
      return MaterialPageRoute(builder: (context) => EmergencyContactsManagementScreen());
    case Routes.START_SAFE_WALK_SCREEN:
      return MaterialPageRoute(builder: (context) => SafeWalkCreationScreen());
    case Routes.SAFE_WALK_WALKER_SCREEN:
      return MaterialPageRoute(builder: (context) => SafeWalkWalkerScreen());
    case Routes.RECEIVED_SAFE_WALK_LIST_SCREEN:
      return MaterialPageRoute(builder: (context) => ReceivedSafeWalkListScreen());
    case Routes.SAFE_WALK_WATCHER_SCREEN:
      var argument = settings.arguments as String;
      return MaterialPageRoute(builder: (context) => SafeWalkWatcherScreen(safeWalkID: argument));
    case Routes.FIREBASE_SMS_CODE_CONFIRMATION_SCREEN:
      var argument = settings.arguments as String;
      return MaterialPageRoute(builder: (context) => PhoneConfirmationFirebaseScreen(verificationId: argument));
    default:
      return MaterialPageRoute(builder: (context) => SplashScreen());
  }
}
