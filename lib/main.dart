import 'package:cryout_app/application.dart';
import 'package:cryout_app/utils/background-location-update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/notification-handler.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHandler.initialize();
  FireBaseHandler.configure();
  setupLocator();
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
        tabBarTheme: TabBarTheme.of(context).copyWith(labelColor: Colors.black, unselectedLabelColor: Colors.grey),
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
        tabBarTheme: TabBarTheme.of(context).copyWith(labelColor: Colors.white, unselectedLabelColor: Colors.grey),
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
      onGenerateRoute: generateRoute,
      navigatorKey: locator<NavigationService>().navigatorKey,
    );
  }
}
