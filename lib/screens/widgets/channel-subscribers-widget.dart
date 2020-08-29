import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/safety-channel.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';
import 'package:flutter_native_admob/native_admob_options.dart';
import 'package:http/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ChannelSubscribersWidget extends StatefulWidget {
  final SafetyChannel channel;

  const ChannelSubscribersWidget({Key key, this.channel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelSubscribersWidgetState(this.channel);
  }
}

class _ChannelSubscribersWidgetState extends State {
  final SafetyChannel _channel;
  List<User> _users = [];
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  Translations _translations;
  double _addHeight = 0;

  NativeAdmobController _nativeAdController = NativeAdmobController();
  StreamSubscription _subscription;

  _ChannelSubscribersWidgetState(this._channel);

  @override
  void initState() {
    super.initState();
    _subscription = _nativeAdController.stateChanged.listen(_onStateChanged);
    _initialLoad();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _nativeAdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    return Column(
      children: [
        Expanded(
          child: SmartRefresher(
            onLoading: _initialLoad,
            onRefresh: _loadMore,
            controller: _refreshController,
            header: WaterDropHeader(
              complete: Text(_translations.text("screens.common.refresh.is-refresh-completed")),
              failed: Text(_translations.text("screens.common.refresh.is-refresh-failed")),
              waterDropColor: Theme.of(context).accentColor,
            ),
            child: _users.length == 0
                ? _getNoItemsView()
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (_, int position) {
                      final item = _users[position];
                      return _getUserView(item, position);
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
                padding: const EdgeInsets.only(top: 0.0, bottom: 8, left: 4, right: 4),
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
    );
  }

  Widget _getUserView(User item, int position) {
    return Padding(
      padding: const EdgeInsets.only(left:8, right:8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 4, bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: item.profilePhoto == null ? "https://via.placeholder.com/44x44?text=|" : item.profilePhoto,
                fadeOutDuration: const Duration(seconds: 1),
                fadeInDuration: const Duration(seconds: 0),
                height: 40,
                width: 40,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                  child: Text(
                    item.fullName(),
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                  child: Divider(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getNoItemsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            _translations.text("screens.channel-subscribers-screen.empty"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.display2.color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ),
      ),
    );
  }

  String cursor = "";
  int page = 0;
  int limit = 20;

  void _initialLoad() async {
    page = 0;
    cursor = "";
    Response response = await ChannelResource.getChannelSubscribers(context, _channel.id, cursor, page, limit);

    if (response.statusCode == HttpStatus.ok) {
      dynamic data = jsonDecode(response.body)["data"];
      cursor = data["cursor"];
      page++;
      _users.clear();
      _refreshController.refreshCompleted();

      try {
        setState(() {
          (data["data"] as List<dynamic>).forEach((element) {
            print(element);
            _users.add(User.fromJson(element));
          });
        });
      } catch (e) {}
    } else {
      _refreshController.refreshFailed();
    }
  }

  void _loadMore() async {
    Response response = await ChannelResource.getChannelSubscribers(context, _channel.id, cursor, page, limit);
    if (response.statusCode == HttpStatus.ok) {
      dynamic data = jsonDecode(response.body)["data"];
      cursor = data["cursor"];
      page++;
      _refreshController.refreshCompleted();
      setState(() {
        (data["data"] as List<dynamic>).forEach((element) {
          print(element);
          _users.add(User.fromJson(element));
        });
      });
    } else {
      _refreshController.refreshFailed();
    }
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
}
