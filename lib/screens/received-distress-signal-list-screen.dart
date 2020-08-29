import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/chat-message.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/user.dart';
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
import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';
import 'package:flutter_native_admob/native_admob_options.dart';
import 'package:http/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReceivedDistressSignalListScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ReceivedDistressSignalListScreenState();
  }
}

class _ReceivedDistressSignalListScreenState extends State {
  static final String testAdUnitId = Platform.isAndroid ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-3940256099942544/3986624511';

  NativeAdmobController _nativeAdController = NativeAdmobController();
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  Translations _translations;
  StreamSubscription _subscription;

  double _addHeight = 0;
  bool _isLoading = false;

  String _currentCursor;

  List<ReceivedDistressSignal> _receivedDistressSignals;

  @override
  void initState() {
    super.initState();
    _subscription = _nativeAdController.stateChanged.listen(_onStateChanged);
    initLoad();
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

    if (_receivedDistressSignals == null) {
      _loadFromDB();
    }

    return _receivedDistressSignals == null
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
        : AnnotatedRegion(
            value: WidgetUtils.updateSystemColors(context),
            child: Scaffold(
              backgroundColor: Theme.of(context).backgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).backgroundColor,
                iconTheme: Theme.of(context).iconTheme,
                elevation: 4,
                centerTitle: false,
                brightness: Theme.of(context).brightness,
                title: Text(_translations.text("screens.distress.signals.title"), style: TextStyle(color: Theme.of(context).iconTheme.color)),
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
                      child: _receivedDistressSignals.length == 0
                          ? _getNoItemsView()
                          : ListView.builder(
                              itemCount: _receivedDistressSignals.length,
                              itemBuilder: (_, int position) {
                                final item = _receivedDistressSignals[position];
                                return _getDistressSignalNotificationView(item, position);
                              },
                            ),
                    ),
                  ),
                  Column(
                    children: [
                      _addHeight == 0 ? SizedBox.shrink() : Divider(height: 0.5,),
                      Container(
                        height: _addHeight,
                        child: Padding(
                          padding: const EdgeInsets.only(top:0.0, bottom: 8, left: 4, right: 4),
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
                                color: Colors.white,
                              ),
                              headlineTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                              ),
                              showMediaContent: true,
                              bodyTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                              ),
                              advertiserTextStyle: NativeTextStyle(
                                color: Theme.of(context).textTheme.headline2.color,
                              ),
                            ),
                            // Don't show loading widget when in loading state
                            loading: Container(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  Widget _getDistressSignalNotificationView(ReceivedDistressSignal receivedDistressSignal, int index) {
    return Dismissible(
      background: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(
            Icons.close,
            color: Colors.red,
          ),
        ),
      ),
      key: Key("${receivedDistressSignal.id}"),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 4, bottom: 0, top: 8),
        child: InkWell(
          onTap: () {
            _checkOutDistressSignal(receivedDistressSignal);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 8.0, top:4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left:8.0, right: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: receivedDistressSignal.photo == null ? "https://via.placeholder.com/44x44?text=|" : receivedDistressSignal.photo,
                      fadeOutDuration: const Duration(seconds: 1),
                      fadeInDuration: const Duration(seconds: 0),
                      height: 50,
                      width: 50,
                    ),
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
                            Expanded(
                                child: Text(
                                  receivedDistressSignal.firstName + " " + receivedDistressSignal.lastName.substring(0, 1) + ".",
                                  style: TextStyle(fontSize: 16, fontWeight: receivedDistressSignal.status == 'ACTIVE' ? FontWeight.bold: FontWeight.normal),
                                )),
                            Text(
                                  (receivedDistressSignal.distance == null ? "" : receivedDistressSignal.distance + "km"),
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(_translations.text("choices.distress.categories.${receivedDistressSignal.detail}"), style: TextStyle(color: Colors.grey))),
                            Text(
                              (receivedDistressSignal.dateCreated == null ? "" : timeago.format(DateTime.fromMillisecondsSinceEpoch(receivedDistressSignal.dateCreated), locale: 'en')),
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left:8.0, bottom: 8),
                        child: Divider(),
                      )
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
      onDismissed: (direction) {
        _ignoreDistressSignal(index, receivedDistressSignal);
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
              _translations.text("screens.distress.signals.empty"),
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

    if (!await SharedPreferenceUtil.getBool("logged.count." + receivedDistressSignal.distressId, false)) {
      User user = await SharedPreferenceUtil.currentUser();
      DatabaseReference reference = database.reference().child('distress_channel').reference().child("${receivedDistressSignal.distressId}").reference().child("messages").reference();

      ChatMessage chatMessage = ChatMessage(
        body: user.shortName() + " ${_translations.text("screens.common.messages.joined")}",
        dateCreated: DateTime.now(),
        displayType: "n",
      );

      reference.push().set(chatMessage.toJSON());

      await SharedPreferenceUtil.setBool("logged.count." + receivedDistressSignal.distressId, true);
    }

    locator<NavigationService>().pushNamed(Routes.SAMARITAN_DISTRESS_CHANNEL_SCREEN, arguments: receivedDistressSignal.distressId);
  }

  void _ignoreDistressSignal(int index, ReceivedDistressSignal receivedDistressSignal) async {
    setState(() {
      _receivedDistressSignals.removeAt(index);
    });

    Response response = await SamaritanResource.dismissDistressSignals(context, receivedDistressSignal.distressId);

    if (response.statusCode != 200) {
      setState(() {
        _receivedDistressSignals.insert(index, receivedDistressSignal);
      });
      return;
    }

    FireBaseHandler.unSubscribeToDistressChannelTopic(receivedDistressSignal.distressId);
    SharedPreferenceUtil.setBool(PreferenceConstants.DISTRESS_CHANNEL_MUTED + receivedDistressSignal.distressId, null);

    if (await SharedPreferenceUtil.getBool("logged.count." + receivedDistressSignal.distressId, false)) {
      User user = await SharedPreferenceUtil.currentUser();
      DatabaseReference reference = database.reference().child('distress_channel').reference().child("${receivedDistressSignal.distressId}").reference().child("messages").reference();

      ChatMessage chatMessage = ChatMessage(
        body: user.shortName() + " ${_translations.text("screens.common.messages.left")}",
        dateCreated: DateTime.now(),
        displayType: "n",
      );

      reference.push().set(chatMessage.toJSON());
      SharedPreferenceUtil.setBool("logged.count." + receivedDistressSignal.distressId, null);
    }

    await ReceivedDistressSignalRepository.delete(receivedDistressSignal);
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
          _addHeight = 85;
        });
        break;

      default:
        break;
    }
  }

  Future<void> _loadFromServer() async {
    if (_refreshController.isRefresh) {
      _currentCursor = null;
    }

    Response response = await SamaritanResource.getUserReceivedDistressSignals(context, _currentCursor);

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

    List<ReceivedDistressSignal> signalsFromServer = (data['data'] as List<dynamic>).map((e) => ReceivedDistressSignal.fromJSON(e)).toList();

    if (_refreshController.isRefresh) {
      await ReceivedDistressSignalRepository.clear();
      _receivedDistressSignals.clear();
      for (int i = 0; i < signalsFromServer.length; i++) {
        await ReceivedDistressSignalRepository.save(signalsFromServer.elementAt(i));
      }
      setState(() {
        _receivedDistressSignals.addAll(signalsFromServer);
      });
    } else {
      _receivedDistressSignals.addAll(signalsFromServer);
    }
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

    List<ReceivedDistressSignal> _ds = await ReceivedDistressSignalRepository.all();

    _refreshController.loadComplete();

    setState(() {
      _receivedDistressSignals = _ds;
    });
  }

  void initLoad() async {
    Response response = await SamaritanResource.getUserReceivedDistressSignals(context, _currentCursor);
    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body)['data'];

      List<ReceivedDistressSignal> signalsFromServer = (data['data'] as List<dynamic>).map((e) => ReceivedDistressSignal.fromJSON(e)).toList();
      await ReceivedDistressSignalRepository.clear();
      _receivedDistressSignals.clear();

      for (int i = 0; i < signalsFromServer.length; i++) {
        await ReceivedDistressSignalRepository.save(signalsFromServer.elementAt(i));
      }

      setState(() {
        _receivedDistressSignals.addAll(signalsFromServer);
      });
    }
  }
}
