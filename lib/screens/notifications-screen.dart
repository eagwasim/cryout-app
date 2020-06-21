import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/notification.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_native_admob/flutter_native_admob.dart';
//import 'package:flutter_native_admob/native_admob_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NotificationScreenState();
  }
}

class _NotificationScreenState extends State {
  bool _isLoading = false;

 // final _nativeAdController = NativeAdmobController();

  @override
  void initState() {
    super.initState();
    NotificationRepository.clearUnreadNotificationCount();
    SharedPreferenceUtil.setString(PreferenceConstants.NEXT_SCREEN_FROM_NOTIFICATION, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        elevation: 0,
        brightness: Theme.of(context).brightness,
        title: Text("Activities", style: TextStyle(color: Theme.of(context).textTheme.headline1.color)),
        actions: <Widget>[
          _isLoading
              ? Center(
                  child: Container(
                      width: 38,
                      height: 38,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )),
                )
              : SizedBox.shrink()
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List>(
              future: NotificationRepository.getAll(),
              initialData: List(),
              builder: (context, snapshot) {
                return snapshot.hasData
                    ? snapshot.data.length == 0
                        ? _getNoItemsView()
                        : ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (_, int position) {
                              final item = snapshot.data[position];
                              //get your item data here ...
                              return _getNotificationView(item, snapshot, position);
                            },
                          )
                    : Center(
                        child: CircularProgressIndicator(),
                      );
              },
            ),
          ),
          Container(
            height: 90,
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(bottom: 20.0),
           /* child: NativeAdmob(
              // Your ad unit id
              adUnitID: Platform.isIOS ? "ca-app-pub-6773273500391344/2976291867" : "ca-app-pub-6773273500391344/8803333610",
              controller: _nativeAdController,
              type: NativeAdmobType.banner,
            ),*/
          ),
        ],
      ),
    );
  }

  Widget _getNotificationView(InAppNotification inAppNotification, AsyncSnapshot<List<dynamic>> snapshot, int index) {
    try {
      if (inAppNotification.notificationType == "DISTRESS_SIGNAL_ALERT") {
        return _getDistressSignalNotificationView(inAppNotification, snapshot, index);
      }
    } catch (e) {
      print(e);
    }

    return SizedBox.shrink();
  }

  Widget _getDistressSignalNotificationView(InAppNotification inAppNotification, AsyncSnapshot<List<dynamic>> snapshot, int index) {
    ReceivedDistressSignal receivedDistressSignal = ReceivedDistressSignal.fromJSON(jsonDecode(inAppNotification.notificationData));

    return Dismissible(
      background: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              Icons.close,
              color: Colors.red,
            ),
          ),
          Expanded(
            child: SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              Icons.close,
              color: Colors.red,
            ),
          ),
        ],
      ),
      key: Key(inAppNotification.notificationId),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                _checkOutDistressSignal(receivedDistressSignal);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: receivedDistressSignal.photo == null ? "https://via.placeholder.com/44x44?text=|" : receivedDistressSignal.photo,
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
                                Expanded(child: Text(receivedDistressSignal.detail, style: TextStyle(fontSize: 18))),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                  receivedDistressSignal.firstName + " " + receivedDistressSignal.lastName.substring(0, 1) + ".",
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                )),
                                Text(
                                  (inAppNotification.dateCreated == null ? "" : timeago.format(DateTime.fromMillisecondsSinceEpoch(inAppNotification.dateCreated), locale: 'en_short')) +
                                      "  ·  " +
                                      (receivedDistressSignal.distance == null ? "" : receivedDistressSignal.distance + "km"),
                                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            )),
      ),
      onDismissed: (direction) {
        _ignoreDistressSignal(inAppNotification, receivedDistressSignal);
        setState(() {
          _isLoading = false;
          snapshot.data.removeAt(index);
        });
        Scaffold.of(context).showSnackBar(SnackBar(content: Text("${receivedDistressSignal.detail} signal dismissed")));
      },
    );
  }

  Widget _getNoItemsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    "assets/images/singing_bird.png",
                    height: 200,
                  ),
                ),
              ],
            ),
            Text(
              "You have no activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.display2.color.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 4,
            )
          ],
        ),
      ),
    );
  }

  void _checkOutDistressSignal(ReceivedDistressSignal receivedDistressSignal) async {
    FireBaseHandler.subscribeToDistressChannelTopic(receivedDistressSignal.distressId);
    locator<NavigationService>().pushNamed(Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN, arguments: receivedDistressSignal);
  }

  void _ignoreDistressSignal(InAppNotification inAppNotification, ReceivedDistressSignal receivedDistressSignal) async {
    FireBaseHandler.unSubscribeToDistressChannelTopic(receivedDistressSignal.distressId);
    SharedPreferenceUtil.setBool(PreferenceConstants.DISTRESS_CHANNEL_MUTED + receivedDistressSignal.distressId, null);

    if (!await SharedPreferenceUtil.getBool("logged.count." + receivedDistressSignal.distressId, false)) {
      var _distressChannelStatRef = database.reference().child('distress_channel').reference().child("${receivedDistressSignal.distressId}").reference().child("stats").reference();
      var dbSS = await _distressChannelStatRef.child("samaritan_count").once();
      var _samaritanCount = dbSS == null || dbSS.value == null ? 0 : dbSS.value as int;
      _distressChannelStatRef.child("samaritan_count").set(_samaritanCount - 1);
      SharedPreferenceUtil.setBool("logged.count." + receivedDistressSignal.distressId, null);
    }

    await NotificationRepository.deleteNotification(inAppNotification);
  }
}
