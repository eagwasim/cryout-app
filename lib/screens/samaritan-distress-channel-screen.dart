import 'dart:async';

import 'package:cryout_app/http/distress-resource.dart';
import 'package:cryout_app/http/user-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/pop-up-menu.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:toast/toast.dart';

class SamaritanDistressChannelScreen extends StatefulWidget {
  final ReceivedDistressSignal receivedDistressSignal;

  const SamaritanDistressChannelScreen({Key key, this.receivedDistressSignal}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SamaritanDistressChannelScreenState(this.receivedDistressSignal);
  }
}

const List<Choice> choices = const <Choice>[
  const Choice(title: ' View location', icon: Icons.map, id: 1),
  const Choice(title: ' Report', icon: Icons.report, id: 2),
];

class _SamaritanDistressChannelScreenState extends State {
  ReceivedDistressSignal _receivedDistressSignal;
  TextEditingController _chatInputTextController;
  String _currentChatMessage = "";

  bool _anchorToBottom = true;
  bool _setUpComplete = false;
  bool _isChannelMuted = false;

  int _samaritanCount = 0;

  DatabaseReference _messageDBRef;
  DatabaseReference _distressChannelStatRef;
  StreamSubscription<Event> _samaritanCountListener;

  User _user;

  _SamaritanDistressChannelScreenState(this._receivedDistressSignal);

  @override
  void initState() {
    super.initState();
    SharedPreferenceUtil.setString(PreferenceConstants.NEXT_SCREEN_FROM_NOTIFICATION, null);
  }

  void _select(Choice choice) {
    if (choice.id == 1) {
      locator<NavigationService>().pushNamed(Routes.VIEW_DISTRESS_LOCATION_ON_MAP_SCREEN, arguments: _receivedDistressSignal);
    } else if (choice.id == 2) {
      _showReportUserDialog(_receivedDistressSignal.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    _chatInputTextController = TextEditingController(text: _currentChatMessage);

    if (!_setUpComplete) {
      _setUp();
    }
    return !_setUpComplete
        ? WidgetUtils.getLoaderWidget(context, "loading...")
        : Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).backgroundColor,
              iconTheme: Theme.of(context).iconTheme,
              title: Column(
                children: <Widget>[
                  Text(
                    _receivedDistressSignal.detail,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.headline1.color),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _receivedDistressSignal.firstName + " " + _receivedDistressSignal.lastName.substring(0, 1) + ". & $_samaritanCount samaritan(s)",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              elevation: 1,
              brightness: Theme.of(context).brightness,
              actions: <Widget>[
                IconButton(
                  icon: Icon(_isChannelMuted ? Icons.notifications_off : Icons.notifications_active),
                  onPressed: () {
                    _toggleMuteDistressChannel();
                  },
                ),
                PopupMenuButton<Choice>(
                  onSelected: _select,
                  itemBuilder: (BuildContext context) {
                    return choices.map((Choice choice) {
                      return PopupMenuItem<Choice>(
                        value: choice,
                        child: Row(
                          children: <Widget>[Icon(choice.icon), Text(choice.title)],
                        ),
                      );
                    }).toList();
                  },
                ),
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
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            decoration: new InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              hintText: "Send message to distress channel...",
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
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.blue[600],
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

    _messageDBRef = database.reference().child('distress_channel').reference().child("${_receivedDistressSignal.distressId}").reference().child("messages").reference();
    _messageDBRef.keepSynced(true);

    _distressChannelStatRef = database.reference().child('distress_channel').reference().child("${_receivedDistressSignal.distressId}").reference().child("stats").reference();

    var dbSS = await _distressChannelStatRef.child("samaritan_count").once();
    _samaritanCount = dbSS == null || dbSS.value == null ? 1 : (dbSS.value as int);

    if (!await SharedPreferenceUtil.getBool("logged.count." + _receivedDistressSignal.distressId, false)) {
      await _distressChannelStatRef.child("samaritan_count").set(_samaritanCount);
      SharedPreferenceUtil.setBool("logged.count." + _receivedDistressSignal.distressId, true);
    }

    _samaritanCountListener = _distressChannelStatRef.child("samaritan_count").onChildChanged.listen((event) {
      setState(() {
        _samaritanCount = event.snapshot.value;
      });
    });
    _isChannelMuted = await SharedPreferenceUtil.getBool("${PreferenceConstants.DISTRESS_CHANNEL_MUTED}${_receivedDistressSignal.distressId}", false);
    setState(() {
      _setUpComplete = true;
    });
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

    DistressResource.notifyDistressChannelOfMessage(
      context,
      _receivedDistressSignal.distressId,
      {
        "senderUserId": _user.id,
        "senderName": _user.firstName + " " + _user.lastName.substring(0, 1) + ".",
        "message": message,
        "distressUserId": _receivedDistressSignal.userId,
        "messageType": "text"
      },
    );

    setState(() {
      _currentChatMessage = "";
    });
  }

  void _toggleMuteDistressChannel() async {
    await SharedPreferenceUtil.setBool("${PreferenceConstants.DISTRESS_CHANNEL_MUTED}${_receivedDistressSignal.distressId}", !_isChannelMuted);

    setState(() {
      _isChannelMuted = !_isChannelMuted;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _samaritanCountListener.cancel();
  }

  static final List<String> _reasons = ["False alarm", "Inappropriate Messages", "Suspicious activities", "Impersonation", "Poses threat", "Spam", "Fraud"];

  void _showReportUserDialog(String userId) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 0),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Report Signal",),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.9),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _reasons
                    .map((e) => Row(
                          children: <Widget>[
                            Expanded(
                              child: FlatButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _reportUser(context, userId, e);
                                },
                                child: Text(e),
                                padding: EdgeInsets.all(4),
                              ),
                            ),
                          ],
                        ))
                    .toList()),
          ),
        );
      },
    );
  }

  Future<void> _reportUser(BuildContext context, String userId, String reason) async {
    Toast.show("Sending report...", context, duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);

    UserResource.reportUser(context, {"userId": userId, "reason": reason});
  }
}
