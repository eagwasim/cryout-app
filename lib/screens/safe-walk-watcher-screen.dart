import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/http/distress-resource.dart';
import 'package:cryout_app/http/safe-walk-resource.dart';
import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/distress-signal.dart';
import 'package:cryout_app/models/received-safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/notification-handler.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class SafeWalkWatcherScreen extends StatefulWidget {
  final String safeWalkID;
  final bool openMessages;

  const SafeWalkWatcherScreen({Key key, this.safeWalkID, this.openMessages}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SafeWalkWatcherScreenState(this.safeWalkID, openMessages: this.openMessages ?? false);
  }
}

class _SafeWalkWatcherScreenState extends State {
  final String _safeWalkID;
  ReceivedSafeWalk _receivedSafeWalk;
  DatabaseReference _messageDBRef;
  Translations _translations;

  PersistentBottomSheetController _persistentBottomSheetController; // <------ Instance variable
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const double CAMERA_ZOOM = 18;
  static const double CAMERA_TILT = 80;
  static const double CAMERA_BEARING = 30;

  bool _setUpComplete = false;
  bool _loadingFailed = false;
  bool _sendingDistressCall = false;

  String _currentChatMessage = "";

  var imageBytes;

  Set<Marker> _markers = Set<Marker>();
  bool _anchorToBottom = true;
  bool openMessages;

  TextEditingController _chatInputTextController;

  List<StreamSubscription<Event>> _locationUpdateSubscription = [];
  Completer<GoogleMapController> _controller = Completer();

  _SafeWalkWatcherScreenState(this._safeWalkID, {this.openMessages});

  User _user;

  @override
  void dispose() {
    if (_locationUpdateSubscription != null) {
      _locationUpdateSubscription.forEach((element) {
        element.cancel();
      });
      _locationUpdateSubscription.clear();
    }
    NotificationHandler.turnOnNotificationForRoute("${Routes.SAFE_WALK_WATCHER_SCREEN}$_safeWalkID");
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    NotificationHandler.turnOnNotificationForRoute("${Routes.SAFE_WALK_WATCHER_SCREEN}$_safeWalkID");
  }

  static double lat = 52.3429908;
  static double lon = 4.9570876;

  LatLng initialLocation = LatLng(lat, lon);
  LatLng _currentLocation;

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    if (!_setUpComplete) {
      _setUp();
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.common.loading"));
    }

    if (_loadingFailed) {
      return _getRetryScreen();
    }

    if (_sendingDistressCall) {
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.distress-category-selection.sending-distress-signal"));
    }

    if (openMessages) {
      openMessages = false;
      Future.delayed(Duration(milliseconds: 300), () {
        _messageWindow();
      });
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_receivedSafeWalk.userFirstName + " " + _receivedSafeWalk.userLastName),
          backgroundColor: Colors.blueAccent,
          brightness: Brightness.dark,
          elevation: 2,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.error_outline),
              onPressed: () {
                _showSendDistressCallDialog();
              },
            ),
            _receivedSafeWalk.userPhoneNumber == null || _receivedSafeWalk.userPhoneNumber == ""
                ? SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.call),
                    onPressed: () {
                      UrlLauncher.launch("tel://${_receivedSafeWalk.userPhoneNumber}");
                    },
                  ),
            IconButton(
              icon: Icon(Icons.message),
              onPressed: () {
                _messageWindow();
              },
            )
          ],
        ),
        body: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            updatePinOnMap();
          },
          initialCameraPosition: CameraPosition(
            target: initialLocation,
            zoom: 11.0,
          ),
          markers: _markers,
        ),
      ),
    );
  }

  Widget _getRetryScreen() {
    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          iconTheme: Theme.of(context).iconTheme,
          title: Text(
            _translations.text(_translations.text("screens.samaritan-distress-channel-screen.failed-to-load")),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
          ),
          elevation: 1,
          brightness: Theme.of(context).brightness,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(_translations.text("screens.samaritan-distress-channel-screen.loading-failed")),
              RaisedButton(
                child: Text(_translations.text("screens.common.retry")),
                onPressed: () {
                  setState(() {
                    _setUpComplete = false;
                    _loadingFailed = false;
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  BitmapDescriptor _userImageMarker;

  void _setUp() async {
    _user = await SharedPreferenceUtil.currentUser();
    _receivedSafeWalk = await SharedPreferenceUtil.getCachedSafeWalkCall(_safeWalkID);

    if (_receivedSafeWalk == null) {
      Response response = await SamaritanResource.getUserReceivedSafeWalk(context, _safeWalkID);

      if (response.statusCode != 200) {
        setState(() {
          _loadingFailed = true;
          _setUpComplete = true;
        });
        return;
      } else {
        _loadingFailed = false;
      }

      _receivedSafeWalk = ReceivedSafeWalk.fromJSON(jsonDecode(response.body)['data']);
      SharedPreferenceUtil.saveCachedSafeWalkCall(_receivedSafeWalk);
    }

    _userImageMarker = await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(100, 100)), Platform.isIOS ? 'assets/images/user_marker.png' : 'assets/images/user_marker_android.png');

    DatabaseReference dbRef = database.reference().child('safe_walk_locations').reference().child("${_receivedSafeWalk.safeWalkId}").reference();
    dbRef.keepSynced(true);
    _messageDBRef = database.reference().child('safe_walk_channel').reference().child("${_receivedSafeWalk.safeWalkId}").reference().child("messages").reference();
    _messageDBRef.keepSynced(true);

    DataSnapshot snapshot = await dbRef.once();

    if (snapshot != null && snapshot.value != null) {
      _currentLocation = LatLng(snapshot.value['lat'], snapshot.value['lon']);
      updatePinOnMap();
    }

    _locationUpdateSubscription.add(dbRef.onValue.listen((event) {
      dynamic value = event.snapshot.value;
      if (value == null) {
        return;
      }
      _currentLocation = LatLng(value['lat'], value['lon']);
      updatePinOnMap();
    }));

    setState(() {
      _setUpComplete = true;
    });
  }

  void updatePinOnMap() async {
    if (_currentLocation == null) {
      return;
    }

    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: _currentLocation,
    );

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));

    setState(() {
      var pinPosition = _currentLocation;
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId(_receivedSafeWalk.safeWalkId),
        draggable: false,
        position: pinPosition,
        icon: _userImageMarker,
        infoWindow: InfoWindow(
          title: _receivedSafeWalk.destination,
          snippet: "${_receivedSafeWalk.userFirstName} ${_receivedSafeWalk.userLastName}",
        ),
      ));
    });
  }

  void _messageWindow() async {
    NotificationHandler.turnOffNotificationForRoute("${Routes.SAFE_WALK_WATCHER_SCREEN}$_safeWalkID");

    double height = MediaQuery.of(context).size.height * 0.6;

    _persistentBottomSheetController = _scaffoldKey.currentState.showBottomSheet(
      (context) {
        _chatInputTextController = TextEditingController(text: _currentChatMessage);
        return Container(
            color: Theme.of(context).backgroundColor,
            height: height,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppBar(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      NotificationHandler.turnOnNotificationForRoute("${Routes.SAFE_WALK_WATCHER_SCREEN}$_safeWalkID");
                      Navigator.of(context).pop();
                    },
                  ),
                  backgroundColor: Theme.of(context).backgroundColor,
                  iconTheme: Theme.of(context).iconTheme,
                  title: Text(
                    _translations.text("screens.common.messages"),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
                  ),
                  elevation: 0,
                  brightness: Theme.of(context).brightness,
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: FirebaseAnimatedList(
                    key: ValueKey<bool>(_anchorToBottom),
                    query: _messageDBRef,
                    reverse: _anchorToBottom,
                    sort: _anchorToBottom ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key) : null,
                    itemBuilder: (BuildContext context, DataSnapshot snapshot, Animation<double> animation, int index) {
                      ChatMessage cm = ChatMessage.fromJSON(snapshot.value);
                      return SizeTransition(
                        sizeFactor: animation,
                        child: WidgetUtils.getChatMessageView(_user, context, cm),
                      );
                    },
                  ),
                ),

                Container(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: WidgetUtils.chatInputPadding(),
                            child: TextField(
                              decoration: new InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(40.0),
                                    ),
                                    borderSide: BorderSide(color: Colors.blueGrey[600])),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(40.0),
                                    ),
                                    borderSide: BorderSide(color: Colors.blueGrey[600])),
                                hintText: _translations.text("screens.safe-walk-creation.hints.chat"),
                              ),
                              autofocus: false,
                              controller: _chatInputTextController,
                              keyboardType: TextInputType.text,
                              style: TextStyle(fontSize: 15),
                              minLines: 1,
                              maxLines: 4,
                              onChanged: (newValue) {
                                _currentChatMessage = newValue;
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: WidgetUtils.chatInputPadding(),
                          child: IconButton(
                            icon: Icon(
                              FontAwesomeIcons.paperPlane,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              _sendMessage(_currentChatMessage);
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ));
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 20,
    );
  }

  void _sendMessage(String message) {
    message = message.trim();
    if (message.isEmpty) {
      return;
    }
    ChatMessage chatMessage = ChatMessage(
      body: message,
      userId: _user.id,
      userName: _user.firstName + " " + _user.lastName.substring(0, 1),
      userProfilePhoto: _user.profilePhoto,
      dateCreated: DateTime.now(),
      displayType: "m",
    );

    _messageDBRef.push().set(chatMessage.toJSON());

    SafeWalkResource.notifySafeWalkChannelOfMessage(
      context,
      _safeWalkID,
      {"senderUserId": _user.id, "senderName": _user.shortName(), "message": message, "safeWalkUserId": _receivedSafeWalk.userId, "messageType": "text"},
    );

    _persistentBottomSheetController.setState(() {
      _currentChatMessage = "";
    });
  }

  void _showSendDistressCallDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 16, right: 16),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(_translations.text("screens.safe-walk.watcher.distress.call.title")),
          content: Text(_translations.text("screens.safe-walk.watcher.distress.call.message")),
          actions: <Widget>[
            FlatButton(
              child: new Text(_translations.text("screens.common.cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: new Text(_translations.text("screens.common.send")),
              onPressed: () {
                Navigator.of(context).pop();
                _sendDistressCall();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendDistressCall() async {
    if (_currentLocation == null) {
      WidgetUtils.showAlertDialog(
          context, _translations.text("screens.safe-walk.watcher.distress.call.error.location.title"), _translations.text("screens.safe-walk.watcher.distress.call.error.location.message"));
      return;
    }

    DistressSignal distressCall = await SharedPreferenceUtil.getCurrentDistressCall();

    if (distressCall != null) {
      WidgetUtils.showAlertDialog(
          context, _translations.text("screens.safe-walk.watcher.distress.call.error.conflict.title"), _translations.text("screens.safe-walk.watcher.distress.call.error.conflict.message"));
      return;
    }
    setState(() {
      _sendingDistressCall = true;
    });

    Response response = await DistressResource.sendDistressCall(context, {"lat": "${_currentLocation.latitude}", "lon": "${_currentLocation.longitude}", "details": "safe-walk-emergency"});

    if (response.statusCode != BaseResource.STATUS_CREATED) {
      setState(() {
        _sendingDistressCall = false;
      });

      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.distress-category-selection.error-in-sending"));
      return;
    }

    Map<String, dynamic> responseData = jsonDecode(response.body)["data"];

    distressCall = DistressSignal.fromJSON(responseData);

    SharedPreferenceUtil.setCurrentDistressCall(distressCall);

    setState(() {
      _sendingDistressCall = false;
    });

    FireBaseHandler.subscribeToDistressChannelTopic("${distressCall.id}");

    locator<NavigationService>().pushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: distressCall);
  }
}
