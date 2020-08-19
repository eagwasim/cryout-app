import 'dart:convert';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/subscribed-channel.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/pub-sub.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_text_drawable/flutter_text_drawable.dart';
import 'package:http/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:cryout_app/utils/extensions.dart';

class SubscribedChannels extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SubscribedChannelsState();
  }
}

class _SubscribedChannelsState extends State with Subscriber {
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  Translations _translations;
  bool _isLoading = false;

  String _currentCursor;

  List<SubscribedChannel> _subscribedChannels;

  @override
  void initState() {
    super.initState();
    initialLoad();

    EventManager.subscribe(Events.CHANNEL_SUBSCRIBED, this);
    EventManager.subscribe(Events.CHANNEL_UNSUBSCRIBED, this);
  }

  @override
  void dispose() {
    EventManager.unsubscribe(Events.CHANNEL_SUBSCRIBED, this);
    EventManager.unsubscribe(Events.CHANNEL_UNSUBSCRIBED, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

    if (_subscribedChannels == null) {
      _loadFromDB();
    }

    return _subscribedChannels == null
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
        : SmartRefresher(
            onLoading: _loadFromServer,
            onRefresh: _loadFromServer,
            controller: _refreshController,
            header: WaterDropHeader(
              complete: Text(_translations.text("screens.common.refresh.is-refresh-completed")),
              failed: Text(_translations.text("screens.common.refresh.is-refresh-failed")),
              waterDropColor: Theme.of(context).accentColor,
            ),
            child: _subscribedChannels.length == 0
                ? _getNoItemsView()
                : ListView.builder(
                    itemCount: _subscribedChannels.length,
                    itemBuilder: (_, int position) {
                      final item = _subscribedChannels[position];
                      return _getSubscribedChannelView(item, position);
                    },
                  ),
          );
  }

  Future<void> initialLoad() async {
    Response response = await ChannelResource.getUserSubscribedChannels(context, _currentCursor);

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body)['data'];

      List<SubscribedChannel> dataFromServer = (data['data'] as List<dynamic>).map((e) => SubscribedChannel.fromJSON(e)).toList();

      await SubscribedChannelRepository.clear();
      _subscribedChannels.clear();

      for (int i = 0; i < dataFromServer.length; i++) {
        await SubscribedChannelRepository.save(dataFromServer.elementAt(i));
      }
      try {
        setState(() {
          _subscribedChannels.addAll(dataFromServer);
        });
      } catch (e) {}
      _updateChannelSubscriptions();
    }
  }

  Future<void> _loadFromServer() async {
    if (_refreshController.isRefresh) {
      _currentCursor = null;
    }

    Response response = await ChannelResource.getUserSubscribedChannels(context, _currentCursor);

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

    List<SubscribedChannel> signalsFromServer = (data['data'] as List<dynamic>).map((e) => SubscribedChannel.fromJSON(e)).toList();

    if (_refreshController.isRefresh) {
      await SubscribedChannelRepository.clear();
      _subscribedChannels.clear();
    }

    for (int i = 0; i < signalsFromServer.length; i++) {
      await SubscribedChannelRepository.save(signalsFromServer.elementAt(i));
    }

    setState(() {
      _subscribedChannels.addAll(signalsFromServer);
    });
    _updateChannelSubscriptions();
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

    List<SubscribedChannel> _ds = await SubscribedChannelRepository.all();

    _refreshController.loadComplete();

    setState(() {
      _subscribedChannels = _ds;
    });
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
                    "assets/images/no_subcription.png",
                    height: 200,
                  ),
                ),
              ],
            ),
            Text(
              _translations.text("screens.channel.subscribed.empty"),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.display2.color.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 4,
            )
          ],
        ),
      ),
    );
  }

  Widget _getSubscribedChannelView(SubscribedChannel item, int position) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4, bottom: 0, top: 8),
      child: InkWell(
        onTap: () {
          locator<NavigationService>().pushNamed(Routes.CHANNEL_INFORMATION_SCREEN, arguments: item.id).then((value) {
            if (value != null && value) {
              locator<NavigationService>().pop(result: true);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 4),
                child: TextDrawable(
                  key: Key("${item.id}-${Theme.of(context).brightness.index}"),
                  text: item.name,
                  backgroundColor: WidgetUtils.colorFromId(context, item.id),
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
                          Expanded(child: Text(item.name.titleCapitalize(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                              child: Text(
                            item.latestPostText == null ? item.description.capitalize() : item.latestPostText.capitalize(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color: Colors.grey),
                          )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Divider(),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  String name() {
    return "subscribed-channels-widget";
  }

  @override
  void notify(String event, {data}) {
    initialLoad();
  }

  Future<void> _updateChannelSubscriptions() async {
    for (int index = 0; index < _subscribedChannels.length; index++) {
      FireBaseHandler.subscribeToChannel(_subscribedChannels[index].id.toString());
    }
  }
}
