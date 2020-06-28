import 'dart:async';
import 'dart:io';

import 'package:cryout_app/http/distress-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/distress-call.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
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
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class VictimDistressChannelScreen extends StatefulWidget {
  final DistressCall distressCall;

  const VictimDistressChannelScreen({Key key, this.distressCall}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VictimDistressChannelScreenState(this.distressCall);
  }
}

class _VictimDistressChannelScreenState extends State {
  DistressCall _distressCall;
  TextEditingController _chatInputTextController;
  Translations _translations;
  String _currentChatMessage = "";

  _VictimDistressChannelScreenState(this._distressCall);

  bool _anchorToBottom = true;
  bool _setUpComplete = false;
  bool _isDismissingDistressCall = false;
  bool _isUploadingImage = false;

  DatabaseReference _messageDBRef;

  User _user;

  @override
  void dispose() {
    NotificationHandler.unsubscribeRoute("${Routes.VICTIM_DISTRESS_CHANNEL_SCREEN}${_distressCall.id}");
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
        : Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.red,
              title: Column(
                children: <Widget>[
                  Text(_translations.text("choices.distress.categories.${_distressCall.details}")),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              elevation: 0,
              centerTitle: false,
              brightness: Brightness.dark,
              actions: <Widget>[
                _isDismissingDistressCall
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
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            decoration: new InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              hintText: _translations.text("screens.samaritan-distress-channel-screen.send-message"),
                            ),
                            autofocus: false,
                            controller: _chatInputTextController,
                            keyboardType: TextInputType.text,
                            style: TextStyle(fontSize: 15),
                            onChanged: (newValue) {
                              _currentChatMessage = newValue;
                            },
                          ),
                        ),
                        _isUploadingImage
                            ? Container(width: 24, height: 24, child: CircularProgressIndicator())
                            : IconButton(
                                icon: Icon(
                                  Icons.image,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  _pickImage(context, ImageSource.gallery);
                                },
                              ),
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            _sendMessage(_currentChatMessage);
                          },
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
  }

  void _setUp() async {
    _user = await SharedPreferenceUtil.currentUser();

    _messageDBRef = database.reference().child('distress_channel').reference().child("${_distressCall.id}").reference().child("messages").reference();
    _messageDBRef.keepSynced(true);

    setState(() {
      _setUpComplete = true;
    });

    NotificationHandler.subscribeRoute("${Routes.VICTIM_DISTRESS_CHANNEL_SCREEN}${_distressCall.id}");
  }

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

    DistressResource.notifyDistressChannelOfMessage(
      context,
      "${_distressCall.id}",
      {
        "senderUserId": _user.id,
        "senderName": _user.firstName + " " + _user.lastName.substring(0, 1) + ".",
        "message": message,
        "distressUserId": _user.id,
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
          title: new Text(_translations.text("screens.victim-distress-channel-screen.resolve")),
          content: new Text(_translations.text("screens.victim-distress-channel-screen.resolve.message")),
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
                _translations.text("screens.victim-distress-channel-screen.resolve"),
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                _closeDistressCall();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _closeDistressCall() async {
    setState(() {
      _isDismissingDistressCall = true;
    });

    Response response = await DistressResource.closeDistressCall(context, _distressCall.id);

    if (response.statusCode == 200) {
      DatabaseReference _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
      _userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).remove();
      DatabaseReference _messageDBRef = database.reference().child('distress_channel').reference().child("${_distressCall.id}").reference().child("messages").reference();

      ChatMessage chatMessage = ChatMessage(
        body: "${_user.shortName()} ${_translations.text("screens.victim-distress-channel-screen.left.the.chat")}",
        userId: _user.id,
        dateCreated: DateTime.now(),
        displayType: "n",
      );

      _messageDBRef.push().set(chatMessage.toJSON());
      FireBaseHandler.subscribeToDistressChannelTopic("${_distressCall.id}");

      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isDismissingDistressCall = false;
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
        DistressResource.notifyDistressChannelOfMessage(
          context,
          "${_distressCall.id}",
          {"senderUserId": _user.id, "senderName": _user.firstName + " " + _user.lastName.substring(0, 1) + ".", "message": url, "distressUserId": _user.id, "messageType": "img"},
        );
      } else {
        setState(() {
          _isUploadingImage = false;
        });

        WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.upload.image.message"));
      }
    } on Exception catch (e) {
      print(e);
      setState(() {
        _isUploadingImage = false;
      });
      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.upload.image.message"));
    }
  }
}
