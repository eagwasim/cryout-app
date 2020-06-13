import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class SamaritanDistressChannelScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SamaritanDistressChannelScreenState();
  }
}

class _SamaritanDistressChannelScreenState extends State {
  ReceivedDistressSignal _receivedDistressSignal;
  TextEditingController _chatInputTextController;
  String _currentChatMessage = "";

  bool _anchorToBottom = true;
  bool _setUpComplete = false;
  bool _isReportingUser = false;

  DatabaseReference _messageDBRef;

  User _user;

  @override
  Widget build(BuildContext context) {
    _chatInputTextController = TextEditingController(text: _currentChatMessage);
    if (_receivedDistressSignal == null) {
      _receivedDistressSignal = ModalRoute.of(context).settings.arguments;
    }
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
                    _receivedDistressSignal.firstName + " " + _receivedDistressSignal.lastName.substring(0, 1) + ".",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.headline1.color),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _receivedDistressSignal.detail,
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
                  icon: Icon(Icons.report),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.map),
                  onPressed: () {},
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
                          icon: Icon(Icons.send),
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

    setState(() {
      _setUpComplete = true;
    });

    _notifyChannelJoined();
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

    setState(() {
      _currentChatMessage = "";
    });
  }

  void _notifyChannelJoined() {
    ChatMessage chatMessage = ChatMessage(
      body: _user.firstName + " " + _user.lastName.substring(0, 1) + " joined",
      displayType: "n",
      dateCreated: DateTime.now(),
    );

    _messageDBRef.push().set(chatMessage.toJSON());
  }

  @override
  void dispose() {
    super.dispose();
    _notifyChannelLeft();
  }

  void _notifyChannelLeft() {
    ChatMessage chatMessage = ChatMessage(
      body: _user.firstName + " " + _user.lastName.substring(0, 1) + " left",
      displayType: "n",
      dateCreated: DateTime.now(),
    );

    _messageDBRef.push().set(chatMessage.toJSON());
  }

  void _showReportUserDialog() {

  }
}
