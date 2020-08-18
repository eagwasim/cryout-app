import 'dart:convert';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/my-channel.dart';
import 'package:cryout_app/screens/channels-screen.dart';
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

class CreatedChannels extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CreatedChannelsState();
  }
}

class _CreatedChannelsState extends State with Subscriber {
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  Translations _translations;

  String _currentCursor;

  List<MyChannel> _myChannels;

  @override
  void initState() {
    super.initState();
    initialLoad();
    EventManager.subscribe(Events.CHANNEL_CREATED, this);
    EventManager.subscribe(Events.CHANNEL_DELETED, this);
  }

  @override
  void dispose() {
    EventManager.unsubscribe(Events.CHANNEL_CREATED, this);
    EventManager.unsubscribe(Events.CHANNEL_DELETED, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

    if (_myChannels == null) {
      _loadFromDB();
    }

    return _myChannels == null
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
            child: _myChannels.length == 0
                ? _getNoItemsView()
                : ListView.builder(
                    itemCount: _myChannels.length,
                    itemBuilder: (_, int position) {
                      final item = _myChannels[position];
                      return _getMyChannelView(item, position);
                    },
                  ),
          );
  }

  Future<void> initialLoad() async {
    Response response = await ChannelResource.getUserCreatedChannels(context, _currentCursor);

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body)['data'];

      print(data);

      List<MyChannel> dataFromServer = (data['data'] as List<dynamic>).map((e) => MyChannel.fromJSON(e)).toList();

      await MyChannelRepository.clear();
      _myChannels.clear();

      for (int i = 0; i < dataFromServer.length; i++) {
        await MyChannelRepository.save(dataFromServer.elementAt(i));
      }

      setState(() {
        _myChannels.addAll(dataFromServer);
      });
    }
  }

  Future<void> _loadFromServer() async {
    if (_refreshController.isRefresh) {
      _currentCursor = null;
    }

    Response response = await ChannelResource.getUserCreatedChannels(context, _currentCursor);

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

    List<MyChannel> signalsFromServer = (data['data'] as List<dynamic>).map((e) => MyChannel.fromJSON(e)).toList();

    if (_refreshController.isRefresh) {
      await MyChannelRepository.clear();
      _myChannels.clear();
    }

    for (int i = 0; i < signalsFromServer.length; i++) {
      await MyChannelRepository.save(signalsFromServer.elementAt(i));
    }

    setState(() {
      _myChannels.addAll(signalsFromServer);
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

    List<MyChannel> _ds = await MyChannelRepository.all();

    _refreshController.loadComplete();

    setState(() {
      if (_myChannels != null) {
        _myChannels.clear();
      } else {
        _myChannels = [];
      }
      _myChannels.addAll(_ds);
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
                    "assets/images/no_channels.png",
                    height: 200,
                  ),
                ),
              ],
            ),
            Text(
              _translations.text("screens.channel.created.empty"),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.display2.color.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 4,
            )
          ],
        ),
      ),
    );
  }

  Widget _getMyChannelView(MyChannel item, int position) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4, bottom: 8),
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
                            item.description.capitalize(),
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
    return "created-channel-widget";
  }

  @override
  void notify(String event, {data}) {
    initialLoad();
  }
}
