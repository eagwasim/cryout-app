import 'package:cryout_app/models/distress-call.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/screens/base-screen.dart';
import 'package:cryout_app/screens/distress-category-selection-screen.dart';
import 'package:cryout_app/screens/introduction-screen.dart';
import 'package:cryout_app/screens/received-distress-signal-list-screen.dart';
import 'package:cryout_app/screens/phone-confirmation-screen.dart';
import 'package:cryout_app/screens/phone-verification-screen.dart';
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

  Future<dynamic> popAndPushNamed(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState.popAndPushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacementNamed(String routeName) {
    return navigatorKey.currentState.pushReplacementNamed(routeName);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName) {
    return navigatorKey.currentState.pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false);
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
    case Routes.BASE_SCREEN:
      return MaterialPageRoute(builder: (context) => BaseScreen());
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
      var argument = settings.arguments as DistressCall;
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
    default:
      return MaterialPageRoute(builder: (context) => SplashScreen());
  }
}
