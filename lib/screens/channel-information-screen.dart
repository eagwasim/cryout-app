import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/safety-channel.dart';
import 'package:cryout_app/screens/widgets/channel-about-widget.dart';
import 'package:cryout_app/screens/widgets/channel-posts-widget.dart';
import 'package:cryout_app/screens/widgets/channel-subscribers-widget.dart';
import 'package:cryout_app/utils/extensions.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/pub-sub.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:share/share.dart';

class ChannelInformationScreen extends StatefulWidget {
  final int channelId;

  const ChannelInformationScreen(this.channelId, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelInformationScreenState(this.channelId);
  }
}

class _ChannelInformationScreenState extends State with SingleTickerProviderStateMixin, ChangeNotifier, Subscriber {
  final int _channelId;

  TabController _tabController;
  bool _setUpComplete = false;
  bool _loadingFailed = false;
  bool _hideFab = false;
  bool _subscriptionUpdating = false;

  Translations _translations;

  SafetyChannel _channel;

  _ChannelInformationScreenState(this._channelId);

  @override
  void initState() {
    super.initState();
    EventManager.subscribe(Events.CHANNEL_DELETED, this);
  }

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    if (_loadingFailed) {
      return _getRetryScreen();
    }

    if (_channel == null) {
      _setUp();
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.common.loading"));
    }

    if (_tabController == null) {
      _tabController = new TabController(vsync: this, length: _tabCount());
      _tabController.addListener(() {
        if (_tabController.index != 0 && !_hideFab) {
          setState(() {
            _hideFab = true;
          });
        } else if (_tabController.index == 0 && _hideFab) {
          setState(() {
            _hideFab = false;
          });
        }
      });
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: DefaultTabController(
        length: _tabCount(),
        child: Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            backgroundColor: WidgetUtils.colorFromId(context, _channelId),
            elevation: 2,
            brightness: Theme.of(context).brightness,
            iconTheme: Theme.of(context).iconTheme,
            title: Text(
              _channel.name.titleCapitalize(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
            ),
            centerTitle: false,
            actions: _getActionButton(),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).tabBarTheme.labelColor,
                  unselectedLabelColor: Theme.of(context).tabBarTheme.unselectedLabelColor,
                  isScrollable: true,
                  tabs: _getTabs(),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _getViews(),
          ),
          floatingActionButton: _channel.role == "ADMIN" && !_hideFab
              ? FloatingActionButton(
                  child: Icon(
                    Icons.edit,
                  ),
                  onPressed: () {
                    locator<NavigationService>().pushNamed(Routes.CHANNEL_POST_CREATION_SCREEN, arguments: _channel).then((value) {
                      if (value != null && value) {
                        EventManager.notify(Events.CHANNEL_POST_CREATED);
                      }
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  void _setUp() async {
    _channel = await SharedPreferenceUtil.getCachedChannel(_channelId.toString());

    if (_channel != null) {
      setState(() {
        _loadingFailed = false;
      });
    }

    Response response = await ChannelResource.getChannel(context, _channelId);

    if (response.statusCode != HttpStatus.ok) {
      setState(() {
        if (_channel == null) {
          _loadingFailed = true;
        }
      });
      return;
    } else {
      _loadingFailed = false;
    }
    dynamic data = jsonDecode(response.body)["data"];
    setState(() {
      _channel = SafetyChannel.fromJSON(data);
    });

    SharedPreferenceUtil.saveCachedChannel(_channel);
  }

  Widget _getRetryScreen() {
    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          iconTheme: Theme.of(context).iconTheme,
          title: Text(
            _translations.text(_translations.text("screens.channel-screen.failed-to-load")),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
          ),
          elevation: 1,
          brightness: Theme.of(context).brightness,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(_translations.text("screens.channel-screen.loading-failed")),
              RaisedButton(
                child: Text(_translations.text("screens.common.retry")),
                onPressed: () {
                  setState(() {
                    _loadingFailed = false;
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getActionButton() {
    List<Widget> widgets = [];
    if (_channel.role == null) {
      widgets.add(
        IconButton(
          icon: Icon(Icons.person_add),
          onPressed: _subscriptionUpdating
              ? null
              : () {
                  subscribe();
                },
        ),
      );
    }
    if (_channel.role == "SUBSCRIBER") {
      widgets.add(IconButton(
        icon: Icon(Icons.check),
        onPressed: _subscriptionUpdating
            ? null
            : () {
                unsubscribe();
              },
      ));
    }

    return widgets;
  }

  int _tabCount() {
    if (_channel.role == "ADMIN") {
      return 3;
    }

    return 2;
  }

  List<Tab> _getTabs() {
    if (_channel.role == "ADMIN") {
      return [Tab(text: "Posts"), Tab(text: "Subscribers"), Tab(text: "About")];
    }
    return [Tab(text: "Posts"), Tab(text: "About")];
  }

  List<Widget> _getViews() {
    if (_channel.role == "ADMIN") {
      return [ChannelPostsWidget(channel: _channel), ChannelSubscribersWidget(channel: _channel), ChannelAboutWidget(channel: _channel)];
    }

    return [ChannelPostsWidget(channel: _channel), ChannelAboutWidget(channel: _channel)];
  }

  void subscribe() async {
    Response resp = await ChannelResource.subscribeToChannel(context, _channelId);
    if (resp.statusCode == HttpStatus.ok) {
      FireBaseHandler.subscribeToChannel(_channelId.toString());
      EventManager.notify(Events.CHANNEL_UNSUBSCRIBED);

      setState(() {
        _channel.role = "SUBSCRIBER";
        _channel.subscriberCount += 1;
        SharedPreferenceUtil.saveCachedChannel(_channel);
        _subscriptionUpdating = false;
      });
    } else {
      setState(() {
        _subscriptionUpdating = false;
      });
    }
  }

  void unsubscribe() async {
    Response resp = await ChannelResource.unsubscribeToChannel(context, _channelId);
    if (resp.statusCode == HttpStatus.ok) {
      FireBaseHandler.unsubscribeToChannel(_channelId.toString());
      EventManager.notify(Events.CHANNEL_SUBSCRIBED);
      setState(() {
        _channel.role = null;
        _channel.subscriberCount -= 1;
        SharedPreferenceUtil.saveCachedChannel(_channel);
        _subscriptionUpdating = false;
      });
    } else {
      setState(() {
        _subscriptionUpdating = false;
      });
    }
  }

  @override
  String name() {
    return "channels-information-screen";
  }

  @override
  void notify(String event, {data}) {
    if (event == Events.CHANNEL_DELETED) {
      Future.delayed(Duration(seconds: 1), () {
        EventManager.unsubscribe(Events.CHANNEL_DELETED, this);
        Navigator.of(context).pop();
      });
    }
  }

  void _shareApp() {
    Share.share('Click to join https://cryout.app/ch/$_channelId', subject: 'Join ${_channel.name}!');
  }
}
