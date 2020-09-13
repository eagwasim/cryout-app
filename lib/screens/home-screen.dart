import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/distress-signal.dart';
import 'package:cryout_app/models/emergency-contact.dart';
import 'package:cryout_app/models/my-channel.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/received-safe-walk.dart';
import 'package:cryout_app/models/safe-walk.dart';
import 'package:cryout_app/models/subscribed-channel.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/screens/static-page-screen.dart';
import 'package:cryout_app/utils/background-location-update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/notification-monitor.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:package_info/package_info.dart';
import 'package:share/share.dart';
import 'package:uni_links/uni_links.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State with WidgetsBindingObserver {
  User _user;
  bool _samaritan;

  Translations _translations;

  DistressSignal _currentDistressCall;
  SafeWalk _safeWalk;

  DatabaseReference _userPreferenceDatabaseReference;
  List<StreamSubscription<Event>> _preferenceListeners = [];
  StreamSubscription _sub;
  PackageInfo _packageInfo;

  int _activeDistressCallCount = 0;
  int _activeSamaritanWalkCount = 0;

  WebNotificationService _webNotificationService;

  @override
  void initState() {
    super.initState();
    FireBaseHandler.requestPermission();
    WidgetsBinding.instance.addObserver(this);
    initUniLinks();
  }

  @override
  void dispose() {
    super.dispose();
    _preferenceListeners.forEach((element) {
      element.cancel();
    });

    if (_sub != null) {
      _sub.cancel();
    }
    if (_webNotificationService != null && _webNotificationService.isBroadcast()) {
      _webNotificationService.stopBroadcast();
    }

    _preferenceListeners = [];

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      _setUp();
    }

    if (_translations == null) {
      _translations = Translations.of(context);
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          iconTheme: Theme.of(context).iconTheme,
          elevation: 0,
          title: Text(
            _translations.text("screens.home.title"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
          ),
          centerTitle: false,
          brightness: Theme.of(context).brightness,
          actions: <Widget>[
            IconButton(
              icon: Icon(FontAwesomeIcons.satelliteDish, size: 20, color: _activeDistressCallCount == 0 ? Colors.grey : Theme.of(context).accentColor),
              onPressed: () {
                locator<NavigationService>().navigateTo(Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN);
              },
            ),
            IconButton(
              icon: Icon(FontAwesomeIcons.streetView, size: 20, color: _activeSamaritanWalkCount == 0 ? Colors.grey : Colors.blueAccent),
              onPressed: () {
                locator<NavigationService>().navigateTo(Routes.RECEIVED_SAFE_WALK_LIST_SCREEN);
              },
            ),
            IconButton(
              icon: Icon(Icons.share, size: 20, color: Colors.grey),
              onPressed: () {
                _shareApp();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            //decoration: WidgetUtils.backgroundDecoration(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _safeWalk == null && _currentDistressCall == null
                      ? _getNoItemsView()
                      : ListView(
                          children: [
                            _currentDistressCall == null
                                ? SizedBox.shrink()
                                : ListTile(
                                    leading: WidgetUtils.glowingIconFor(context, FontAwesomeIcons.exclamationCircle, Theme.of(context).accentColor),
                                    trailing: Icon(
                                      FontAwesomeIcons.chevronRight,
                                      size: 14,
                                    ),
                                    title: Text(_translations.text("screens.home.active-distress-signal")),
                                    subtitle: Text(_translations.text("choices.distress.categories.${_currentDistressCall.details}")),
                                    onTap: () {
                                      locator<NavigationService>().pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: _currentDistressCall);
                                    },
                                  ),
                            _currentDistressCall == null
                                ? SizedBox.shrink()
                                : Divider(
                                    indent: 75,
                                  ),
                            _safeWalk == null
                                ? SizedBox.shrink()
                                : ListTile(
                                    leading: WidgetUtils.glowingIconFor(context, FontAwesomeIcons.walking, Colors.blueAccent),
                                    trailing: Icon(
                                      FontAwesomeIcons.chevronRight,
                                      size: 14,
                                    ),
                                    title: Text(_translations.text("screens.home.active-safe-walk")),
                                    subtitle: Text(
                                      _translations.text("screens.common.to") + ": " + _safeWalk.destination.toLowerCase(),
                                    ),
                                    onTap: () {
                                      locator<NavigationService>().pushNamed(Routes.SAFE_WALK_WALKER_SCREEN, arguments: _safeWalk);
                                    },
                                  ),
                            _safeWalk == null
                                ? SizedBox.shrink()
                                : Divider(
                                    indent: 75,
                                  ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 8),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (_safeWalk != null) {
                                  WidgetUtils.showAlertDialog(context, "Active!", "You have an active safe walk. Complete before starting another");
                                  return;
                                }
                                locator<NavigationService>().pushNamed(Routes.START_SAFE_WALK_SCREEN).then((value) => _setUp());
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.walking,
                                      color: Colors.blueAccent,
                                      size: 44,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                    ),
                                    Text(
                                      _translations.text("screens.safe-walk-creation.title"),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 8),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (_currentDistressCall != null) {
                                  WidgetUtils.showAlertDialog(context, "Active", "You have an active distress signal. Resolve before sending another.");
                                  return;
                                }
                                locator<NavigationService>().pushNamed(Routes.DISTRESS_CATEGORY_SELECTION_SCREEN).then((value) => _setUp());
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.exclamationCircle,
                                      color: Theme.of(context).accentColor,
                                      size: 44,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                    ),
                                    Text(
                                      _translations.text("screens.home.call-to-action"),
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                    // shrinkWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void updateSamaritanMode(BuildContext context, bool _samaritanModeEnabled) async {
    Response resp = await SamaritanResource.updateSamaritanMode(context, {"samaritanModeEnabled": _samaritanModeEnabled});

    if (resp.statusCode != 200) {
      _samaritanModeEnabled = !_samaritanModeEnabled;
    }

    if (_userPreferenceDatabaseReference == null) {
      _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
    }

    _userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).set(_samaritanModeEnabled);

    setState(() {
      _samaritan = _samaritanModeEnabled;
    });

    _updateLocationTrackingStatus();
  }

  void _updateLocationTrackingStatus() async {
    if (_samaritan != null && _samaritan) {
      FireBaseHandler.subscribeToSamaritanTopic(_user.id);
      BackgroundLocationUpdate.startLocationTracking();
    } else if (_samaritan != null && !_samaritan) {
      if (!await SharedPreferenceUtil.isSafeWalking()) {
        BackgroundLocationUpdate.stopLocationTracking();
      }
      FireBaseHandler.unSubscribeToSamaritanTopic(_user.id);
    }
  }

  void _setUp() async {
    if (_webNotificationService == null) {
      _webNotificationService = WebNotificationService(context);

      _webNotificationService.startBroadCast();
      _webNotificationService.counts.listen((event) {
        try {
          setState(() {
            _activeSamaritanWalkCount = event.activeSafeWalkCount;
            _activeDistressCallCount = event.activeDistressCallCount;
          });
        } catch (ignore) {}
      });
    }

    if (_user == null) {
      User user = await SharedPreferenceUtil.currentUser();

      setState(() {
        _user = user;
      });
    }

    DistressSignal distressCall = await SharedPreferenceUtil.getCurrentDistressCall();
    SafeWalk safeWalk = await SharedPreferenceUtil.getCurrentSafeWalk();
    try {
      setState(() {
        _currentDistressCall = distressCall;
        _safeWalk = safeWalk;
      });
    } catch (e) {}
    if (_userPreferenceDatabaseReference == null) {
      _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
      _userPreferenceDatabaseReference.keepSynced(true);
    }

    var dbSS = await _userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).once();
    _samaritan = dbSS == null || dbSS.value == null ? false : dbSS.value;

    if (_preferenceListeners.isEmpty) {
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).onChildRemoved.listen((event) {
        setState(() {
          _currentDistressCall = null;
        });
      }));
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).onChildAdded.listen((event) {
        setState(() {
          _currentDistressCall = DistressSignal.fromJSON(event.snapshot.value);
        });
      }));
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).onChildChanged.listen((event) {
        setState(() {
          _currentDistressCall = DistressSignal.fromJSON(event.snapshot.value);
        });
      }));
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_SAFE_WALK).onChildRemoved.listen((event) {
        setState(() {
          _safeWalk = null;
        });
      }));
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_SAFE_WALK).onChildAdded.listen((event) {
        setState(() {
          _safeWalk = SafeWalk.fromJSON(event.snapshot.value);
        });
      }));
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_SAFE_WALK).onChildChanged.listen((event) {
        setState(() {
          _safeWalk = SafeWalk.fromJSON(event.snapshot.value);
        });
      }));
    }
    try {
      setState(() {});
    } catch (e) {}
    _updateLocationTrackingStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      if (_webNotificationService != null) {
        _webNotificationService.startBroadCast();
      }
    } else if (state == AppLifecycleState.inactive) {
      if (_webNotificationService != null) {
        _webNotificationService.stopBroadcast();
      }
      // app is inactive
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
      if (_webNotificationService != null) {
        _webNotificationService.stopBroadcast();
      }
    } else if (state == AppLifecycleState.detached) {
      if (_webNotificationService != null) {
        _webNotificationService.stopBroadcast();
      }
    }
  }

  void _shareApp() {
    Share.share('Get Cry Out! Your personal safety app https://cryout.app/dl', subject: 'Download Cry Out');
  }

  Future<Null> initUniLinks() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String initialLink = await getInitialLink();
      openLink(initialLink);

      _sub = getLinksStream().listen((String link) {
        openLink(link);
      }, onError: (err) {
        // Handle exception by warning the user their action did not succeed
      });
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
  }

  void openLink(String appLink) {
    if (appLink == null) {
      return;
    }
    if (appLink.startsWith("https://cryout.app/ch/")) {
      String channelId = appLink.split("/").last;
      locator<NavigationService>().pushNamed(Routes.CHANNEL_INFORMATION_SCREEN, arguments: int.parse(channelId));
    }
  }

  Widget _getNoItemsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Hi ${_user == null ? "" : _user.fullName()}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.display2.color.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Get help right away from the bottom of your screen.\nSend a distress signal if you are in distress or have your emergency contacts watch you while you try to get to your destination by starting a safe walk.",
              style: Theme.of(context).textTheme.caption,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  "assets/images/home_screen_empty.png",
                  width: MediaQuery.of(context).size.width * .8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
