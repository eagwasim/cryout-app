import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/distress-resource.dart';
import 'package:cryout_app/http/user-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/distress-call.dart';
import 'package:cryout_app/models/notification.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/background_location_update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
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
  bool _hasPendingNotifications = false;

  DistressCall _currentDistressCall;

  DatabaseReference _userPreferenceDatabaseReference;
  List<StreamSubscription<Event>> _preferenceListeners = [];

  @override
  void initState() {
    super.initState();
    FireBaseHandler.requestPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

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

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        elevation: 0,
        title: Text(
          "Personal Safety",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.headline1.color),
        ),
        centerTitle: true,
        brightness: Theme.of(context).brightness,
        leading: IconButton(
          icon: Icon(Icons.rss_feed, color: _hasPendingNotifications ? Colors.deepOrange : Colors.grey),
          onPressed: () {
            Future<dynamic> resp = Navigator.pushNamed(context, Routes.NOTIFICATIONS_SCREEN);
            resp.then((value) => {updateNotifications()});
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: _user == null ? "https://via.placeholder.com/44x44?text=|" : _user.profilePhoto,
                fadeOutDuration: const Duration(seconds: 1),
                fadeInDuration: const Duration(seconds: 3),
                height: 28,
                width: 28,
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(4),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Hi " + (_user == null ? "" : (_user.lastName + " " + _user.firstName)),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(8),
            ),
            _currentDistressCall == null
                ? SizedBox.shrink()
                : Row(
                    children: <Widget>[
                      Expanded(
                          child: Padding(
                        padding: EdgeInsets.only(left: 8, right: 8, bottom: 4),
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
                                      "${_currentDistressCall.details}",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  WidgetUtils.glowingIconFor(context, Icons.error_outline, Colors.deepOrange)
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: _currentDistressCall).then((value) => {
                                    if (value) {print("VALUE RETURNEDDDDDDDDDDDDDDDDDDDDDDD"), _setUp()}
                                  });
                            },
                          ),
                        ),
                      ))
                    ],
                  ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Card(
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              _user == null ? "assets/images/superman.png" : _user.gender == "MALE" ? "assets/images/superman.png" : "assets/images/superwoman.png",
                              height: 140,
                            ),
                          ),
                          Divider(),
                          Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16),
                                child: Text(
                                  "Samaritan mode",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.help_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () {},
                              ),
                              Switch(
                                value: _samaritan != null && _samaritan,
                                onChanged: (value) {
                                  setState(() {
                                    _samaritan = value;
                                  });

                                  updateSamaritanMode(context, value);
                                },
                              )
                            ],
                          )
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentDistressCall == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RaisedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.DISTRESS_CATEGORY_SELECTION_SCREEN).then((value) => {_setUp()});
                },
                icon: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                label: Text(
                  "Send Distress Signal",
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
    Response resp = await UserResource.updateSamaritanMode(context, {"samaritanModeEnabled": _samaritanModeEnabled});

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

    _hasPendingNotifications = await NotificationRepository.hasUnReadNotifications();

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
      bool hasNotification = await NotificationRepository.hasUnReadNotifications();
      setState(() {
        _hasPendingNotifications = hasNotification;
      });
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
    }
  }

  void updateNotifications() async {
    bool hasNotification = await NotificationRepository.hasUnReadNotifications();
    setState(() {
      _hasPendingNotifications = hasNotification;
    });
  }
}
