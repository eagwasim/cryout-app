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
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:package_info/package_info.dart';

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

  PackageInfo _packageInfo;

  int _activeDistressCallCount = 0;
  int _activeSamaritanWalkCount = 0;

  WebNotificationService _webNotificationService;

  @override
  void initState() {
    super.initState();
    FireBaseHandler.requestPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    _preferenceListeners.forEach((element) {
      element.cancel();
    });

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
              icon: Icon(FontAwesomeIcons.satelliteDish, color: _activeDistressCallCount == 0 ? Colors.grey : Theme.of(context).accentColor),
              onPressed: () {
                locator<NavigationService>().navigateTo(Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN);
              },
            ),
            IconButton(
              icon: Icon(FontAwesomeIcons.walking, color: _activeSamaritanWalkCount == 0 ? Colors.grey : Colors.blueAccent),
              onPressed: () {
                locator<NavigationService>().navigateTo(Routes.RECEIVED_SAFE_WALK_LIST_SCREEN);
              },
            ),
            IconButton(
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: _user == null ? "https://via.placeholder.com/44x44?text=|" : _user.profilePhoto,
                  height: 28,
                  width: 28,
                ),
              ),
              onPressed: () {
                _showUserDetails();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 8, top: 8),
                      child: Text(
                        _translations.text("screens.common.hi") + " " + (_user == null ? "" : _user.fullName()),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, bottom: 8, right: 20.0),
                  child: Divider(),
                ),
                _currentDistressCall == null
                    ? SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8, right: 16),
                        child: Text(
                          _translations.text("screens.home.active-distress-signal"),
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                _currentDistressCall == null
                    ? SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 8, top: 8, bottom: 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      _translations.text("choices.distress.categories.${_currentDistressCall.details}"),
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  WidgetUtils.glowingIconFor(context, FontAwesomeIcons.exclamationCircle, Colors.deepOrange)
                                ],
                              ),
                            ),
                            onTap: () {
                              locator<NavigationService>().pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: _currentDistressCall);
                            },
                          ),
                        )),
                _safeWalk == null
                    ? SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8, right: 16),
                        child: Text(
                          _translations.text("screens.home.active-safe-walk"),
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                _safeWalk == null
                    ? SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 8, top: 8, bottom: 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      _translations.text("screens.common.to") + ": " + _safeWalk.destination.toLowerCase(),
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  WidgetUtils.glowingIconFor(context, FontAwesomeIcons.walking, Colors.blueAccent)
                                ],
                              ),
                            ),
                            onTap: () {
                              locator<NavigationService>().pushNamed(Routes.SAFE_WALK_WALKER_SCREEN, arguments: _safeWalk);
                            },
                          ),
                        )),
                _safeWalk == null && _currentDistressCall == null
                    ? SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 20.0, bottom: 8, right: 20.0),
                        child: Divider(),
                      ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            child: Image.asset(
                              _user == null ? "assets/images/superman.png" : _user.gender == "MALE" ? "assets/images/superman.png" : "assets/images/superwoman.png",
                              height: 100,
                              width: 100,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white70,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          _translations.text("screens.home.samaritan-mode"),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      activeColor: Theme.of(context).accentColor,
                                      value: _samaritan != null && _samaritan,
                                      onChanged: (value) {
                                        setState(() {
                                          _samaritan = value;
                                        });
                                        updateSamaritanMode(context, value);
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    )
                                  ],
                                ),
                              ),
                              Divider(),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  _translations.text("screens.home.samaritan-mode.details"),
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1,
                      child: InkWell(
                        onTap: () {
                          locator<NavigationService>().pushNamed(Routes.MANAGE_EMERGENCY_CONTACTS_SCREEN);
                        },
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16, top: 16),
                              child: Text(
                                _translations.text("screens.home.emergency-contacts"),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SizedBox.shrink(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 8),
                              child: Icon(
                                FontAwesomeIcons.chevronRight,
                                size: 14,
                              ),
                            )
                          ],
                        ),
                      ),
                    )),
                Expanded(
                  child: SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      _safeWalk == null
                          ? Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      locator<NavigationService>().pushNamed(Routes.START_SAFE_WALK_SCREEN).then((value) => _setUp());
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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
                            )
                          : SizedBox.shrink(),
                      _currentDistressCall == null
                          ? Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      locator<NavigationService>().pushNamed(Routes.DISTRESS_CATEGORY_SELECTION_SCREEN).then((value) => _setUp());
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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
                          : SizedBox.shrink(),
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

    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
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
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).onChildChanged.listen((event) {
        setState(() {
          _samaritan = event.snapshot.value == true;
        });
      }));
      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).onChildRemoved.listen((event) {
        setState(() {
          _samaritan = false;
        });
      }));
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

    setState(() {});
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

  void _showUserDetails() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 0),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: Container(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: _user.profilePhoto == null ? "https://via.placeholder.com/44x44?text=|" : _user.profilePhoto,
                        fadeOutDuration: const Duration(seconds: 1),
                        fadeInDuration: const Duration(seconds: 0),
                        height: 40,
                        width: 40,
                      ),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 0.0, left: 8.0, top: 0, bottom: 4),
                            child: Row(
                              children: <Widget>[
                                Expanded(child: Text(_user.firstName + " " + _user.lastName, style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                  _translations.text("screens.name-update.hints.gender.${_user.gender.toLowerCase()}").toLowerCase() + " | " + _user.phoneNumber,
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
                Divider(),
                FlatButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showLogOutDialog();
                    },
                    icon: Icon(
                      FontAwesomeIcons.signOutAlt,
                      size: 14,
                    ),
                    label: Text(_translations.text("screens.home.log-out")),
                    padding: EdgeInsets.all(4)),
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            _translations.text("screens.home.privacy-policy"),
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          locator<NavigationService>().pushNamed(Routes.STATIC_WEB_PAGE_VIEW_SCREEN, arguments: WebPageModel("Privacy Policy", "${BaseResource.BASE_URL}/pages/privacy-policy"));
                        },
                      ),
                      Text(" • "),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            _translations.text("screens.home.terms-of-service"),
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          locator<NavigationService>().pushNamed(Routes.STATIC_WEB_PAGE_VIEW_SCREEN, arguments: WebPageModel("Terms of Service", "${BaseResource.BASE_URL}/pages/terms-of-service"));
                        },
                      ),
                      Text(" • "),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          _packageInfo.version,
                          style: TextStyle(fontSize: 10),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 1),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(_translations.text("screens.home.log-out")),
          content: Text(_translations.text("screens.home.log-out.details")),
          actions: <Widget>[
            FlatButton(
              child: Text(_translations.text("screens.common.cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(
                _translations.text("screens.home.log-out"),
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logOutOfApplication();
              },
            )
          ],
        );
      },
    );
  }

  void _logOutOfApplication() async {
    await FireBaseHandler.unsubscribeFromAllTopics();

    await ReceivedDistressSignalRepository.clear();
    await ReceivedSafeWalkRepository.clear();
    await EmergencyContactRepository.clear();
    await SubscribedChannelRepository.clear();
    await MyChannelRepository.clear();

    await BackgroundLocationUpdate.stopLocationTracking();

    await SharedPreferenceUtil.clear();

    await FirebaseAuth.instance.signOut();

    locator<NavigationService>().pushNamedAndRemoveUntil(Routes.PHONE_VERIFICATION_SCREEN);
  }
}
