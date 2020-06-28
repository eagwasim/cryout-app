import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/distress-call.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/recieved-safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/screens/static-page-screen.dart';
import 'package:cryout_app/utils/background_location_update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

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

  DistressCall _currentDistressCall;

  DatabaseReference _userPreferenceDatabaseReference;
  List<StreamSubscription<Event>> _preferenceListeners = [];

  @override
  void initState() {
    super.initState();
    FireBaseHandler.requestPermission();
  }

  @override
  void dispose() {
    super.dispose();
    _preferenceListeners.forEach((element) {
      element.cancel();
    });
    _preferenceListeners = [];
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      _setUp();
    }

    if (_translations == null) {
      _translations = Translations.of(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        elevation: 0,
        title: Text(
          _translations.text("screens.home.title"),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.headline1.color),
        ),
        centerTitle: false,
        brightness: Theme.of(context).brightness,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.rss_feed, color: Colors.grey),
            onPressed: () {
              locator<NavigationService>().navigateTo(Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN);
            },
          ),
          IconButton(
            icon: Icon(Icons.directions_walk, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: _user == null ? "https://via.placeholder.com/44x44?text=|" : _user.profilePhoto,
                fadeOutDuration: const Duration(seconds: 1),
                fadeInDuration: const Duration(seconds: 1),
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
        child: ListView(
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
                              WidgetUtils.glowingIconFor(context, Icons.error_outline, Colors.deepOrange)
                            ],
                          ),
                        ),
                        onTap: () {
                          locator<NavigationService>().pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: _currentDistressCall);
                        },
                      ),
                    )),
            _currentDistressCall == null
                ? SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 20.0, bottom: 8, right: 20.0),
                    child: Divider(),
                  ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Card(
                elevation: 2,
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
                          _user.getWalkingImageAsset(),
                          height: 90,
                          width: 90,
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
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _translations.text("screens.home.safe-walk"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              FlatButton(
                                onPressed: () {
                                  locator<NavigationService>().pushNamed(Routes.START_SAFE_WALK_SCREEN).then((value) => {_setUp()});
                                },
                                child: Text(
                                  _translations.text("screens.home.safe-walk.start"),
                                  style: TextStyle(color: Theme.of(context).accentColor),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.only(right: 0, left: 0, bottom: 0, top: 0),
                              )
                            ],
                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _translations.text("screens.home.safe-walk.detail"),
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
                elevation: 2,
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
                          height: 90,
                          width: 90,
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
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _translations.text("screens.home.samaritan-mode"),
                                    style: TextStyle(
                                      fontSize: 16,
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
              padding: EdgeInsets.all(16),
              child: Center(
                  child: Text(
                _translations.text("screens.home.fine-print"),
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.caption.color.withAlpha(100),
                ),
                textAlign: TextAlign.center,
              )),
            )
          ],
          shrinkWrap: false,
        ),
      ),
      floatingActionButton: _currentDistressCall == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RaisedButton.icon(
                elevation: 4,
                onPressed: () {
                  locator<NavigationService>().pushNamed(Routes.DISTRESS_CATEGORY_SELECTION_SCREEN).then((value) => {_setUp()});
                },
                icon: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                label: Text(
                  _translations.text("screens.home.call-to-action"),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.all(16),
              ),
            )
          : SizedBox.shrink(),
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

  void _updateLocationTrackingStatus() {
    if (_samaritan != null && _samaritan) {
      BackgroundLocationUpdate.startLocationTracking();
      FireBaseHandler.subscribeToSamaritanTopic(_user.id);
    } else if (_samaritan != null && !_samaritan) {
      BackgroundLocationUpdate.stopLocationTracking();
      FireBaseHandler.unSubscribeToSamaritanTopic(_user.id);
    }
  }

  void _setUp() async {
    if (_user == null) {
      _user = await SharedPreferenceUtil.currentUser();

      setState(() {});
    }

    if (_userPreferenceDatabaseReference == null) {
      _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
      _userPreferenceDatabaseReference.keepSynced(true);
    }

    var dbSS = await _userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).once();
    _samaritan = dbSS == null || dbSS.value == null ? false : dbSS.value;

    dbSS = await _userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).once();
    _currentDistressCall = (dbSS == null || dbSS.value == null) ? null : DistressCall.fromJSON(dbSS.value);

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

      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).onChildChanged.listen((event) {
        setState(() {
          _currentDistressCall = event.snapshot.value;
        });
      }));

      _preferenceListeners.add(_userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).onChildRemoved.listen((event) {
        setState(() {
          _currentDistressCall = null;
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

    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
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
                                  _user.emailAddress,
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                                )),
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
                    locator<NavigationService>().pushNamed(Routes.MANAGE_EMERGENCY_CONTACTS_SCREEN);
                  },
                  icon: Icon(Icons.group),
                  label: Text(_translations.text("screens.home.emergency-contacts")),
                  padding: EdgeInsets.all(4),
                ),
                Divider(),
                FlatButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showLogOutDialog();
                    },
                    icon: Icon(Icons.exit_to_app),
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
    await BackgroundLocationUpdate.stopLocationTracking();
    await SharedPreferenceUtil.clear();
    locator<NavigationService>().pushNamedAndRemoveUntil(Routes.INTRODUCTION_SCREEN);
  }
}
