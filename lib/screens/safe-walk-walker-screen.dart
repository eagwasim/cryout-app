import 'dart:io';

import 'package:cryout_app/http/safe-walk-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/background-location-update.dart';
import 'package:cryout_app/utils/battery-monitor.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/notification-handler.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';

class SafeWalkWalkerScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SafeWalkWalkerScreenState();
  }
}

class _SafeWalkWalkerScreenState extends State {
  SafeWalk _currentSafeWalk;
  TextEditingController _chatInputTextController;
  Translations _translations;
  String _currentChatMessage = "";

  bool _anchorToBottom = true;
  bool _setUpComplete = false;
  bool _isDismissingSafeWalk = false;
  bool _isUploadingImage = false;

  DatabaseReference _messageDBRef;

  User _user;

  DeviceInformationService _deviceInformationService = DeviceInformationService();

  @override
  void dispose() {
    if (_currentSafeWalk != null) {
      NotificationHandler.turnOnNotificationForRoute("${Routes.SAFE_WALK_WALKER_SCREEN}${_currentSafeWalk.id}");
    }

    _deviceInformationService.stopBroadcast();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _chatInputTextController = TextEditingController(text: _currentChatMessage);
    _translations = Translations.of(context);

    if (!_setUpComplete) {
      _setUp();
    }

    return !_setUpComplete
        ? WidgetUtils.getLoaderWidget(context, _translations.text("screens.common.loading"))
        : AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
          child: Scaffold(
              backgroundColor: Theme.of(context).backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.blueAccent,
                title: Column(
                  children: <Widget>[
                    Text(_translations.text("screens.home.safe-walk")),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _currentSafeWalk.destination,
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    )
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                elevation: 4,
                centerTitle: false,
                brightness: Brightness.dark,
                actions: <Widget>[
                  _isDismissingSafeWalk
                      ? Container(
                          width: 55,
                          height: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            _showCloseDistressDialog();
                          },
                        )
                ],
              ),
              body: Column(
                children: <Widget>[
                  Flexible(
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
                  Divider(
                    height: 1,
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
                                maxLines: 4,
                                minLines: 1,
                                onChanged: (newValue) {
                                  _currentChatMessage = newValue;
                                },
                              ),
                            ),
                          ),
                          _isUploadingImage
                              ? SizedBox.shrink()
                              : Padding(
                                  padding: WidgetUtils.chatInputPadding(),
                                  child: IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.image,
                                      color: Colors.blueGrey[600],
                                    ),
                                    onPressed: () {
                                      _pickImage(context, ImageSource.gallery);
                                    },
                                  ),
                                ),
                          _isUploadingImage
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: WidgetUtils.chatInputPadding(),
                                  child: IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.cameraRetro,
                                      color: Colors.blueGrey[600],
                                    ),
                                    onPressed: () {
                                      _pickImage(context, ImageSource.camera);
                                    },
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
                  )
                ],
              ),
            ),
        );
  }

  int lastBatteryLevel;

  void _setUp() async {
    _user = await SharedPreferenceUtil.currentUser();
    _currentSafeWalk = await SharedPreferenceUtil.getCurrentSafeWalk();

    if (_currentSafeWalk == null) {
      locator<NavigationService>().pop(result: true);
      return;
    }

    _messageDBRef = database.reference().child('safe_walk_channel').reference().child("${_currentSafeWalk.id}").reference().child("messages").reference();
    _messageDBRef.keepSynced(true);

    _deviceInformationService.batteryLevel.listen((event) async {
      int currentBatteryLevel = event.batteryLevel;

      if (lastBatteryLevel == null) {
        lastBatteryLevel = currentBatteryLevel;
      }

      // Is charging
      if (lastBatteryLevel < currentBatteryLevel) {
        if (currentBatteryLevel > 20) {
          SharedPreferenceUtil.setBool("safe-walk-channel.${_currentSafeWalk.id}.low-battery-notified", false);
        }
        return;
      }

      lastBatteryLevel = currentBatteryLevel;

      if (currentBatteryLevel < 20) {
        if (!await SharedPreferenceUtil.getBool("safe-walk-channel.${_currentSafeWalk.id}.low-battery-notified", false)) {
          SharedPreferenceUtil.setBool("safe-walk-channel.${_currentSafeWalk.id}.low-battery-notified", true);
          _sendLowBatteryNotification();
        }
      }
    });

    setState(() {
      _setUpComplete = true;
    });

    NotificationHandler.turnOffNotificationForRoute("${Routes.SAFE_WALK_WALKER_SCREEN}${_currentSafeWalk.id}");
    location.changeSettings(accuracy: LocationAccuracy.navigation, distanceFilter: 0, interval: 2000);
    location.onLocationChanged.listen((LocationData currentLocation) {
      SharedPreferenceUtil.updateUserLastKnownSafeWalkLocation("${_currentSafeWalk.id}", currentLocation.latitude, currentLocation.longitude);
    });
  }

  Location location = new Location();

  void _sendMessage(String message) {
    ChatMessage chatMessage = ChatMessage(
      body: message,
      userId: _user.id,
      userName: _user.firstName + " " + _user.lastName.substring(0, 1),
      userProfilePhoto: _user.profilePhoto,
      dateCreated: DateTime.now(),
      displayType: "m",
    );

    _messageDBRef.push().set(chatMessage.toJSON());

    setState(() {
      _currentChatMessage = "";
    });

    SafeWalkResource.notifySafeWalkChannelOfMessage(
      context,
      "${_currentSafeWalk.id}",
      {
        "senderUserId": _user.id,
        "senderName": _user.firstName + " " + _user.lastName.substring(0, 1) + ".",
        "message": message,
        "safeWalkUserId": _user.id,
        "messageType": "text",
      },
    );
  }

  void _showCloseDistressDialog() {
    // flutter defined function
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
          title: new Text(_translations.text("screens.safe-walk-creation.close.dialog.title")),
          content: new Text(_translations.text("screens.safe-walk-creation.close.dialog.message")),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text(_translations.text("screens.common.cancel"), style: TextStyle(color: Colors.deepOrange)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                _translations.text("screens.common.end"),
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                _endSafeWalk();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _endSafeWalk() async {
    setState(() {
      _isDismissingSafeWalk = true;
    });

    Response response = await SafeWalkResource.closeSafeWalk(context, _currentSafeWalk.id);

    if (response.statusCode == 200) {
      SharedPreferenceUtil.setSafeWalk(null);

      DatabaseReference _messageDBRef = database.reference().child('safe_walk_channel').reference().child("${_currentSafeWalk.id}").reference().child("messages").reference();

      ChatMessage chatMessage = ChatMessage(
        body: "${_user.shortName()} ${_translations.text("screens.safe-walk.walker-screen.left.the.chat")}",
        userId: _user.id,
        dateCreated: DateTime.now(),
        displayType: "n",
      );

      _messageDBRef.push().set(chatMessage.toJSON());

      FireBaseHandler.unSubscribeToSafeWalkChannelTopic("${_currentSafeWalk.id}");

      SharedPreferenceUtil.endSafeWalk();

      DatabaseReference _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
      DataSnapshot dbSS = await _userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).once();

      bool _samaritan = dbSS == null || dbSS.value == null ? false : dbSS.value;

      if (!_samaritan) {
        BackgroundLocationUpdate.stopLocationTracking();
      }

      SafeWalkResource.notifySafeWalkChannelOfMessage(
        context,
        "${_currentSafeWalk.id}",
        {
          "senderUserId": _user.id,
          "senderName": "${_translations.text("screens.safe-walk.walker-screen.ended.title")}",
          "message": "${_user.fullName()} ${_translations.text("screens.safe-walk.walker-screen.ended.message")}",
          "safeWalkUserId": _user.id,
          "messageType": "text"
        },
      );

      locator<NavigationService>().pop(result: true);
    } else {
      setState(() {
        _isDismissingSafeWalk = false;
      });
    }
  }

  /// Select an image via gallery or camera
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    PickedFile selected = await ImagePicker().getImage(source: source, maxHeight: 512, maxWidth: 512);
    if (selected != null) {
      _uploadImage(context, File.fromUri(Uri.file(selected.path)));
    }
  }

  void _uploadImage(BuildContext context, File file) async {
    setState(() {
      _isUploadingImage = true;
    });
    var uuid = Uuid();
    String filename = uuid.v1() + ".jpg";
    try {
      StorageReference storageReference = FirebaseStorage.instance.ref().child("images/$filename");

      final StorageUploadTask uploadTask = storageReference.putFile(file);
      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      final String url = (await downloadUrl.ref.getDownloadURL());

      if (url != null) {
        ChatMessage chatMessage = ChatMessage(
          body: url,
          userId: _user.id,
          userName: _user.firstName + " " + _user.lastName.substring(0, 1),
          userProfilePhoto: _user.profilePhoto,
          dateCreated: DateTime.now(),
          displayType: "img",
        );

        _messageDBRef.push().set(chatMessage.toJSON());
        setState(() {
          _isUploadingImage = false;
        });
        SafeWalkResource.notifySafeWalkChannelOfMessage(
          context,
          "${_currentSafeWalk.id}",
          {"senderUserId": _user.id, "senderName": _user.firstName + " " + _user.lastName.substring(0, 1) + ".", "message": url, "safeWalkUserId": _user.id, "messageType": "img"},
        );
      } else {
        setState(() {
          _isUploadingImage = false;
        });

        WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.upload.image.message"));
      }
    } on Exception catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.upload.image.message"));
    }
  }

  void _sendLowBatteryNotification() async {
    await SafeWalkResource.notifySafeWalkChannelOfMessage(
      context,
      "${_currentSafeWalk.id}",
      {
        "senderUserId": _user.id,
        "senderName": "${_translations.text("screens.safe-walk.walker-screen.battery.low.title")}",
        "message": "${_user.fullName()}${_translations.text("screens.safe-walk.walker-screen.battery.low.message")}",
        "safeWalkUserId": _user.id,
        "messageType": "text"
      },
    );
  }

  @override
  void initState() {
    _deviceInformationService.broadcastBatteryLevel();

    super.initState();
  }
}
