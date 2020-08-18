import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/channel-post.dart';
import 'package:cryout_app/models/safety-channel.dart';
import 'package:cryout_app/utils/pub-sub.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChannelPostsWidget extends StatefulWidget {
  final SafetyChannel channel;

  const ChannelPostsWidget({Key key, this.channel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelPostsWidgetState(this.channel);
  }
}

class _ChannelPostsWidgetState extends State with Subscriber {
  final SafetyChannel _channel;
  Translations _translations;

  _ChannelPostsWidgetState(this._channel);

  String cursor = "";
  int page = 0;
  int limit = 100;

  List<ChannelPost> _channelPosts = [];
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _initialLoad();
    EventManager.subscribe(Events.CHANNEL_POST_CREATED, this);
  }

  @override
  void dispose() {
    super.dispose();
    EventManager.unsubscribe(Events.CHANNEL_POST_CREATED, this);
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
      child: _channelPosts.length == 0
          ? _getNoItemsView()
          : ListView.builder(
              itemCount: _channelPosts.length,
              itemBuilder: (_, int position) {
                final item = _channelPosts[position];
                return _getItemView(item, position);
              },
            ),
    );
  }

  Widget _getNoItemsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            _translations.text("screens.channel-post.screen.empty"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyText1.color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ),
      ),
    );
  }

  void _initialLoad() async {
    Response response = await ChannelResource.getChannelPosts(context, _channel.id, cursor, page, limit);
    page = 0;
    if (response.statusCode == HttpStatus.ok) {
      dynamic data = jsonDecode(response.body)["data"];
      cursor = data["cursor"];
      page++;
      _channelPosts.clear();
      _refreshController.refreshCompleted();
      setState(() {
        (data["data"] as List<dynamic>).forEach((element) {
          _channelPosts.add(ChannelPost.fromJSON(element));
        });
      });
    } else {
      _refreshController.refreshFailed();
    }
  }

  void _loadMore() async {
    Response response = await ChannelResource.getChannelPosts(context, _channel.id, cursor, page, limit);
    if (response.statusCode == HttpStatus.ok) {
      dynamic data = jsonDecode(response.body)["data"];
      cursor = data["cursor"];
      page++;
      _refreshController.refreshCompleted();
      setState(() {
        (data["data"] as List<dynamic>).forEach((element) {
          _channelPosts.add(ChannelPost.fromJSON(element));
        });
      });
    } else {
      _refreshController.refreshFailed();
    }
  }

  Widget _getItemView(ChannelPost item, int position) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 4, top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: item.creatorImage == null ? "https://via.placeholder.com/44x44?text=|" : item.creatorImage,
                    fadeOutDuration: const Duration(seconds: 1),
                    fadeInDuration: const Duration(seconds: 0),
                    height: 30,
                    width: 30,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
                      child: Text(
                        item.creatorName,
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 8, right: 8, bottom: 4),
                      child: Text(
                        item.dateCreated == null ? "" : timeago.format(DateTime.fromMillisecondsSinceEpoch(item.dateCreated), locale: 'en'),
                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: Colors.grey),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 8, right: 8),
            child: Text(item.message),
          ),
        ],
      )),
    );
  }

  @override
  String name() {
    return "channel-posts-widget";
  }

  @override
  void notify(String event, {data}) {
    _initialLoad();
  }
}
