import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/channel.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ChannelSubscribersWidget extends StatefulWidget {
  final Channel channel;

  const ChannelSubscribersWidget({Key key, this.channel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelSubscribersWidgetState(this.channel);
  }
}

class _ChannelSubscribersWidgetState extends State {
  final Channel _channel;
  List<User> _users = [];
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  Translations _translations;

  _ChannelSubscribersWidgetState(this._channel);

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    return SmartRefresher(
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
    );
  }

  Widget _getUserView(User item, int position) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left:8.0, right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: item.profilePhoto == null ? "https://via.placeholder.com/44x44?text=|" : item.profilePhoto ,
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
                  padding: const EdgeInsets.only(top:20.0, left: 8, right: 8),
                  child: Text(item.fullName(), textAlign: TextAlign.start, style: TextStyle(fontSize: 16),),
                ),
                Padding(
                  padding: const EdgeInsets.only(top:8.0, left: 8, right: 8),
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
  int limit = 100;

  void _initialLoad() async {
    Response response = await ChannelResource.getChannelSubscribers(context, _channel.id, cursor, page, limit);
    page = 0;
    if (response.statusCode == HttpStatus.ok) {
      dynamic data = jsonDecode(response.body)["data"];
      cursor = data["cursor"];
      page++;
      _users.clear();
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
}
