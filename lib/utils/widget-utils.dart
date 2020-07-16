import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/user-resource.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:toast/toast.dart';

class WidgetUtils {
  static BoxDecoration getDefaultGradientBackground() {
    return BoxDecoration(
      // Box decoration takes a gradient
      gradient: LinearGradient(
        // Where the linear gradient begins and ends
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        // Add one stop for each color. Stops should increase from 0 to 1
        stops: [0.2, 0.5, 0.7, 0.9],

        colors: [
          // Colors are easy thanks to Flutter's Colors class.
          Colors.indigo[800],
          Colors.indigo[600],
          Colors.indigo[300],
          Colors.indigo[100],
        ],
      ),
    );
  }

  static BoxDecoration getLightGradientBackground() {
    return BoxDecoration(
      // Box decoration takes a gradient
      gradient: LinearGradient(
        // Where the linear gradient begins and ends
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        // Add one stop for each color. Stops should increase from 0 to 1
        stops: [0.1, 0.5, 0.7, 0.9],

        colors: [
          // Colors are easy thanks to Flutter's Colors class.
          Colors.white,
          Colors.white,
          Colors.white,
          Colors.white,
        ],
      ),
    );
  }

  static void showAlertDialog(BuildContext context, String title, String message) {
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
          title: new Text(title),
          content: new Text(message),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Widget getLoaderWidget(BuildContext context, String text) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 100.0,
              width: 100.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                strokeWidth: 8.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
            ),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(text)),
          ],
        ),
      ),
    );
  }

  static Widget getColoredLoaderWidget(String text, Color color) {
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 100.0,
              width: 100.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 8.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  text,
                  style: TextStyle(color: Colors.white),
                )),
          ],
        ),
      ),
    );
  }

  static Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  static Widget glowingNotification(BuildContext context) {
    return AvatarGlow(
      startDelay: Duration(milliseconds: 2000),
      glowColor: Colors.red,
      endRadius: 20.0,
      duration: Duration(milliseconds: 2000),
      repeat: true,
      showTwoGlows: true,
      shape: BoxShape.circle,
      repeatPauseDuration: Duration(milliseconds: 100),
      child: IconButton(
        icon: Icon(
          Icons.notifications_none,
          color: Colors.red.withOpacity(0.8),
        ),
        onPressed: () {
          Navigator.pushNamed(context, Routes.RECEIVED_DISTRESS_SIGNAL_SCREEN);
        },
      ),
    );
  }

  static Widget glowingIconFor(BuildContext context, IconData iconData, Color color) {
    return AvatarGlow(
      startDelay: Duration(milliseconds: 2000),
      glowColor: color,
      endRadius: 14.0,
      duration: Duration(milliseconds: 2000),
      repeat: true,
      showTwoGlows: true,
      shape: BoxShape.circle,
      repeatPauseDuration: Duration(milliseconds: 100),
      child: Icon(
        iconData,
        color: color.withOpacity(0.8),
      ),
    );
  }

  static Widget _getOtherChatView(BuildContext context, ChatMessage cm) {
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                _showReportUserDialog(context, cm.userId);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: cm.userProfilePhoto == null ? "https://via.placeholder.com/44x44?text=|" : cm.userProfilePhoto,
                  height: 28,
                  width: 28,
                ),
              ),
            ),
            Bubble(
              margin: BubbleEdges.only(top: 10),
              alignment: Alignment.topLeft,
              nip: BubbleNip.leftBottom,
              color: Colors.grey[900],
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cm.body,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        cm.userName + " · " + timeago.format(cm.dateCreated, locale: 'en_short'),
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 8, color: Colors.grey[200]),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _getOtherChatImageView(BuildContext context, ChatMessage cm) {
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                _showReportUserDialog(context, cm.userId);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: cm.userProfilePhoto == null ? "https://via.placeholder.com/44x44?text=|" : cm.userProfilePhoto,
                  height: 28,
                  width: 28,
                ),
              ),
            ),
            Bubble(
              margin: BubbleEdges.only(top: 10),
              alignment: Alignment.topLeft,
              nip: BubbleNip.leftBottom,
              color: Colors.grey[900],
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: cm.body == null ? "https://via.placeholder.com/44x44?text=|" : cm.body,
                        height: 150,
                        width: 150,
                      ),
                      onTap: () {
                        _showLargeImage(context, cm.body);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        cm.userName == null ? "" : cm.userName + " · " + timeago.format(cm.dateCreated, locale: 'en_short'),
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 8, color: Colors.grey[200]),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _getUserChatView(BuildContext context, ChatMessage cm) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Bubble(
        margin: BubbleEdges.only(top: 0),
        alignment: Alignment.topRight,
        nip: BubbleNip.rightBottom,
        color: Colors.blue[600],
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                cm.body,
                style: TextStyle(color: Colors.white, fontSize: 14),
                softWrap: true,
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  timeago.format(cm.dateCreated, locale: 'en_short'),
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 8, color: Colors.grey[200]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  static Widget _getUserChatImageView(BuildContext context, ChatMessage cm) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Bubble(
        margin: BubbleEdges.only(top: 0),
        alignment: Alignment.topRight,
        nip: BubbleNip.rightBottom,
        color: Colors.blue[600],
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              InkWell(
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: cm.body == null ? "https://via.placeholder.com/44x44?text=|" : cm.body,
                  height: 150,
                  width: 150,
                ),
                onTap: () {
                  _showLargeImage(context, cm.body);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  timeago.format(cm.dateCreated, locale: 'en_short'),
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 8, color: Colors.grey[200]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  static Widget _getSeparatorView(ChatMessage cm) {
    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Center(
          child: Text(
            cm.body + " · " + timeago.format(cm.dateCreated, locale: 'en_short'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.0,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ));
  }

  static Widget getChatMessageView(User user, BuildContext context, ChatMessage cm) {
    if (cm.displayType == "n") {
      return _getSeparatorView(cm);
    } else if (cm.displayType == "img" && cm.userId == user.id) {
      return _getUserChatImageView(context, cm);
    } else if (cm.displayType == "img" && cm.userId != user.id) {
      return _getOtherChatImageView(context, cm);
    } else if (cm.userId != user.id) {
      return _getOtherChatView(context, cm);
    } else {
      return _getUserChatView(context, cm);
    }
  }

  static void _showLargeImage(BuildContext context, String imageUrl) {
    Translations _trans = Translations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 0, right: 0),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: SingleChildScrollView(
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: imageUrl,
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              child: new Text(_trans.text("screens.common.done")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Widget getCounterBadgeForIcon(IconData iconData, int counter, Color color) {
    return new Stack(
      children: <Widget>[
        Icon(iconData),
        counter != 0
            ? new Positioned(
                right: 11,
                top: 11,
                child: new Container(
                  padding: EdgeInsets.all(2),
                  decoration: new BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$counter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : new Container()
      ],
    );
  }

  static final List<String> _reasons = ["inappropriate-message", "suspicious-activities", "impersonation", "poses-threat", "spam", "fraud"];

  static void _showReportUserDialog(BuildContext context, String userId) {
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
              Text("Report user"),
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

  static Future<void> _reportUser(BuildContext context, String userId, String reason) async {
    Toast.show("Sending report...", context, duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);

    UserResource.reportUser(context, {"userId": userId, "reason": reason});
  }

  static EdgeInsetsGeometry chatInputPadding(){
    double top = 8;
    double bottom = Platform.isIOS ? 20 : 16;
    return EdgeInsets.only(top: top, bottom: bottom);
  }
}
