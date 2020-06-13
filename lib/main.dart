import 'package:cryout_app/application.dart';
import 'package:cryout_app/screens/base-screen.dart';
import 'package:cryout_app/screens/distress-category-selection-screen.dart';
import 'package:cryout_app/screens/introduction-screen.dart';
import 'package:cryout_app/screens/notifications-screen.dart';
import 'package:cryout_app/screens/phone-confirmation-screen.dart';
import 'package:cryout_app/screens/phone-verification-screen.dart';
import 'package:cryout_app/screens/samaritan-distress-channel-screen.dart';
import 'package:cryout_app/screens/splash-screen.dart';
import 'package:cryout_app/screens/user-profile-picture-update-screen.dart';
import 'package:cryout_app/screens/user-profile-update-screen.dart';
import 'package:cryout_app/screens/victim-distress-channel-screen.dart';
import 'package:cryout_app/utils/background_location_update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

final FirebaseDatabase database = FirebaseDatabase.instance;

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState<MyApp> extends State {
  SpecificLocalizationDelegate _localeOverrideDelegate;

  @override
  void initState() {
    super.initState();

    _localeOverrideDelegate = SpecificLocalizationDelegate(null);
    applic.onLocaleChanged = onLocaleChange;

    FireBaseHandler.configure();

    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(100000000);
  }

  onLocaleChange(Locale locale) {
    setState(() {
      _localeOverrideDelegate = SpecificLocalizationDelegate(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    //SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    // Setup location Tracking
    BackgroundLocationUpdate.setUpLocationTracking(context);

    return MaterialApp(
      title: 'Cry Out',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        _localeOverrideDelegate,
        const TranslationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: applic.supportedLocales(),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blueAccent,
        accentColor: Colors.pink,
        dividerColor: Colors.grey,
        cardColor: Colors.white,
        //primarySwatch: Colors.grey,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
        buttonTheme: ButtonThemeData(buttonColor: Colors.pink, textTheme: ButtonTextTheme.normal, height: 40),
        // Define the default font family.
        fontFamily: 'Raleway',
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.white),
        backgroundColor: Colors.white,
        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          title: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
          body1: TextStyle(
            fontSize: 14.0,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        accentColor: Colors.pink,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.pink,
          textTheme: ButtonTextTheme.primary,
          height: 40,
        ),
        cardColor: Colors.grey[900],
        // Define the default font family.
        fontFamily: 'Raleway',
        backgroundColor: Colors.black,
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.grey[900]),
        dividerColor: Colors.grey,
        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          title: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
          body1: TextStyle(
            fontSize: 14.0,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[50]),
      ),
      initialRoute: Routes.SPLASH_SCREEN,
      routes: {
        Routes.INTRODUCTION_SCREEN: (context) => AppIntroductionScreen(),
        Routes.BASE_SCREEN: (context) => BaseScreen(),
        Routes.SPLASH_SCREEN: (context) => SplashScreen(),
        Routes.PHONE_VERIFICATION_SCREEN: (context) => PhoneVerificationScreen(),
        Routes.PHONE_CONFIRMATION_SCREEN: (context) => PhoneConfirmationScreen(),
        Routes.USER_PROFILE_UPDATE_SCREEN: (context) => UserProfileUpdateScreen(),
        Routes.USER_PROFILE_PHOTO_UPDATE_SCREEN: (context) => UserProfilePictureUpdateScreen(),
        Routes.DISTRESS_CATEGORY_SELECTION_SCREEN: (context) => DistressCategorySelectionScreen(),
        Routes.VICTIM_DISTRESS_CHANNEL_SCREEN: (context) => VictimDistressChannelScreen(),
        Routes.NOTIFICATIONS_SCREEN: (context) => NotificationScreen(),
        Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN: (context) => SamaritanDistressChannelScreen(),
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
