import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/recieved-safe-walk.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';
import 'package:flutter_native_admob/native_admob_options.dart';
import 'package:http/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReceivedSafeWalkListScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ReceivedSafeWalkListScreenState();
  }
}

class _ReceivedSafeWalkListScreenState extends State {
  static final String testAdUnitId = Platform.isAndroid ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-3940256099942544/3986624511';

  NativeAdmobController _nativeAdController = NativeAdmobController();
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  Translations _translations;
  StreamSubscription _subscription;

  double _addHeight = 0;
  bool _isLoading = false;

  String _currentCursor;

  List<ReceivedSafeWalk> _receivedSafeWalkList;

  @override
  void initState() {
    super.initState();
    _subscription = _nativeAdController.stateChanged.listen(_onStateChanged);
    ReceivedDistressSignalRepository.markAllAsOpened();
    initialLoad();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _nativeAdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

    if (_receivedSafeWalkList == null) {
      _loadFromDB();
    }

    return _receivedSafeWalkList == null
        ? Center(
            child: Container(
              width: 38,
              height: 38,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).backgroundColor,
              iconTheme: Theme.of(context).iconTheme,
              elevation: 0,
              brightness: Theme.of(context).brightness,
              title: Text(_translations.text("screens.safe-walk.signals.title"), style: TextStyle(color: Theme.of(context).textTheme.headline1.color)),
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
                  child: SmartRefresher(
                    onLoading: _loadFromServer,
                    onRefresh: _loadFromServer,
                    controller: _refreshController,
                    header: WaterDropHeader(
                      complete: Text(_translations.text("screens.common.refresh.is-refresh-completed")),
                      failed: Text(_translations.text("screens.common.refresh.is-refresh-failed")),
                      waterDropColor: Theme.of(context).accentColor,
                    ),
                    child: _receivedSafeWalkList.length == 0
                        ? _getNoItemsView()
                        : ListView.builder(
                            itemCount: _receivedSafeWalkList.length,
                            itemBuilder: (_, int position) {
                              final item = _receivedSafeWalkList[position];
                              return _getSafeWalkNotificationView(item, position);
                            },
                          ),
                  ),
                ),
                Container(
                  height: _addHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: NativeAdmob(
                          // Your ad unit id
                          adUnitID: Platform.isIOS ? FireBaseHandler.IOS_NATIVE_AD_UNIT_ID : FireBaseHandler.ANDROID_NATIVE_AD_UNIT_ID,
                          controller: _nativeAdController,
                          type: NativeAdmobType.banner,
                          options: NativeAdmobOptions(
                              adLabelTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                              ),
                              callToActionStyle: NativeTextStyle(
                                backgroundColor: Theme.of(context).accentColor,
                                color: Theme.of(context).textTheme.button.color,
                              ),
                              headlineTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                                fontSize: Theme.of(context).textTheme.headline2.fontSize,
                              ),
                              showMediaContent: true,
                              bodyTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                                fontSize: Theme.of(context).textTheme.bodyText1.fontSize,
                              ),
                              advertiserTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                              )),
                          // Don't show loading widget when in loading state
                          loading: Container(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _getSafeWalkNotificationView(ReceivedSafeWalk receivedSafeWalkSignal, int index) {
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
      key: Key("${receivedSafeWalkSignal.id}"),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                _checkOutSafeWalkSignal(receivedSafeWalkSignal);
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
                        imageUrl: receivedSafeWalkSignal.userPhoto == null ? "https://via.placeholder.com/44x44?text=|" : receivedSafeWalkSignal.userPhoto,
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
                                Expanded(child: Text(receivedSafeWalkSignal.userFirstName + " " + receivedSafeWalkSignal.userLastName, style: TextStyle(fontSize: 18))),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                  receivedSafeWalkSignal.destination,
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                )),
                                Text(
                                  receivedSafeWalkSignal.dateCreated == null ? "" : timeago.format(DateTime.fromMillisecondsSinceEpoch(receivedSafeWalkSignal.dateCreated), locale: 'en_short'),
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
        _ignoreSafeWalk(index, receivedSafeWalkSignal);
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
                    "assets/images/no_safe_walk.png",
                    height: 200,
                  ),
                ),
              ],
            ),
            Text(
              _translations.text("screens.safe-walk.signals.empty"),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.display2.color.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 4,
            )
          ],
        ),
      ),
    );
  }

  void _checkOutSafeWalkSignal(ReceivedSafeWalk receivedSafeWalk) async {
    FireBaseHandler.subscribeSafeWalkChannelTopic(receivedSafeWalk.safeWalkId);

    if (!await SharedPreferenceUtil.getBool("safe-walk.logged." + receivedSafeWalk.safeWalkId, false)) {
      User user = await SharedPreferenceUtil.currentUser();
      DatabaseReference reference = database.reference().child('safe_walk_channel').reference().child("${receivedSafeWalk.safeWalkId}").reference().child("messages").reference();

      ChatMessage chatMessage = ChatMessage(
        body: user.shortName() + " ${_translations.text("screens.common.messages.joined")}",
        dateCreated: DateTime.now(),
        displayType: "n",
      );

      reference.push().set(chatMessage.toJSON());

      await SharedPreferenceUtil.setBool("safe-walk.logged." + receivedSafeWalk.safeWalkId, true);
    }

    locator<NavigationService>().pushNamed(Routes.SAFE_WALK_WATCHER_SCREEN, arguments: receivedSafeWalk.safeWalkId);
  }

  void _ignoreSafeWalk(int index, ReceivedSafeWalk receivedSafeWalk) async {
    setState(() {
      _receivedSafeWalkList.removeAt(index);
    });

    Response response = await SamaritanResource.dismissSafeWalk(context, receivedSafeWalk.safeWalkId);

    if (response.statusCode != 200) {
      setState(() {
        _receivedSafeWalkList.insert(index, receivedSafeWalk);
      });
      return;
    }

    FireBaseHandler.unSubscribeToSafeWalkChannelTopic(receivedSafeWalk.safeWalkId);

    SharedPreferenceUtil.setBool(PreferenceConstants.SAFE_WALK_CHANNEL_MUTED + receivedSafeWalk.safeWalkId, null);

    if (!await SharedPreferenceUtil.getBool("safe-walk.logged." + receivedSafeWalk.safeWalkId, false)) {
      User user = await SharedPreferenceUtil.currentUser();
      DatabaseReference reference = database.reference().child('safe_walk_channel').reference().child("${receivedSafeWalk.safeWalkId}").reference().child("messages").reference();

      ChatMessage chatMessage = ChatMessage(
        body: user.shortName() + " ${_translations.text("screens.common.messages.left")}",
        dateCreated: DateTime.now(),
        displayType: "n",
      );

      await reference.push().set(chatMessage.toJSON());
      await SharedPreferenceUtil.setBool("safe-walk.logged." + receivedSafeWalk.safeWalkId, false);
    }

    await ReceivedSafeWalkRepository.delete(receivedSafeWalk);
  }

  void _onStateChanged(AdLoadState state) {
    switch (state) {
      case AdLoadState.loading:
        setState(() {
          _addHeight = 0;
        });
        break;

      case AdLoadState.loadCompleted:
        setState(() {
          _addHeight = 124;
        });
        break;

      default:
        break;
    }
  }

  Future<void> initialLoad() async {
    Response response = await SamaritanResource.getUserReceivedSafeWalks(context, _currentCursor);

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body)['data'];
      List<ReceivedSafeWalk> signalsFromServer = (data['data'] as List<dynamic>).map((e) => ReceivedSafeWalk.fromJSON(e)).toList();

      await ReceivedSafeWalkRepository.clear();
      _receivedSafeWalkList.clear();

      for (int i = 0; i < signalsFromServer.length; i++) {
        await ReceivedSafeWalkRepository.save(signalsFromServer.elementAt(i));
      }

      setState(() {
        _receivedSafeWalkList.addAll(signalsFromServer);
      });
    }
  }

  Future<void> _loadFromServer() async {
    if (_refreshController.isRefresh) {
      _currentCursor = null;
    }

    Response response = await SamaritanResource.getUserReceivedSafeWalks(context, _currentCursor);

    print(response.statusCode);
    if (response.statusCode != 200) {
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      } else if (_refreshController.isLoading) {
        _refreshController.loadFailed();
      }
      return;
    }

    dynamic data = jsonDecode(response.body)['data'];

    _currentCursor = data['cursor'];

    List<ReceivedSafeWalk> signalsFromServer = (data['data'] as List<dynamic>).map((e) => ReceivedSafeWalk.fromJSON(e)).toList();

    if (_refreshController.isRefresh) {
      await ReceivedSafeWalkRepository.clear();
      _receivedSafeWalkList.clear();
    }

    for (int i = 0; i < signalsFromServer.length; i++) {
      await ReceivedSafeWalkRepository.save(signalsFromServer.elementAt(i));
    }

    setState(() {
      _receivedSafeWalkList.addAll(signalsFromServer);
    });

    _refreshController.refreshCompleted();

    return signalsFromServer;
  }

  bool _loadedFromDB = false;

  Future<void> _loadFromDB() async {
    if (_loadedFromDB) {
      return;
    } else {
      _loadedFromDB = true;
    }

    List<ReceivedSafeWalk> _ds = await ReceivedSafeWalkRepository.all();

    _refreshController.loadComplete();

    setState(() {
      _receivedSafeWalkList = _ds;
    });
  }
}
