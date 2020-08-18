import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/safety-channel.dart';
import 'package:cryout_app/screens/widgets/channel-about-widget.dart';
import 'package:cryout_app/screens/widgets/channel-posts-widget.dart';
import 'package:cryout_app/screens/widgets/channel-subscribers-widget.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/pub-sub.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:cryout_app/utils/extensions.dart';

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

    if (!_setUpComplete) {
      _setUp();
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.common.loading"));
    }

    if (_loadingFailed) {
      return _getRetryScreen();
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
            elevation: 0,
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
    Response response = await ChannelResource.getChannel(context, _channelId);

    if (response.statusCode != HttpStatus.ok) {
      setState(() {
        _loadingFailed = true;
        _setUpComplete = true;
      });
      return;
    } else {
      _loadingFailed = false;
    }

    dynamic data = jsonDecode(response.body)["data"];

    setState(() {
      _setUpComplete = true;
      _channel = SafetyChannel.fromJSON(data);
    });
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
                    _setUpComplete = false;
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
    if (_channel.role == null) {
      return [
        FlatButton.icon(
          label: Text("Subscribe"),
          icon: Icon(FontAwesomeIcons.bell, size: 14),
          onPressed: _subscriptionUpdating
              ? null
              : () {
                  subscribe();
                },
        )
      ];
    } else if (_channel.role == "SUBSCRIBER") {
      return [
        FlatButton.icon(
          label: Text("Unsubscribe"),
          icon: Icon(FontAwesomeIcons.bellSlash, size: 14),
          onPressed: _subscriptionUpdating
              ? null
              : () {
                  unsubscribe();
                },
        )
      ];
    }
    return [];
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

  var adminTabs;
  var otherTabs;

  List<Widget> _getViews() {
    if (_channel.role == "ADMIN") {
      if (adminTabs == null) {
        adminTabs = [ChannelPostsWidget(channel: _channel), ChannelSubscribersWidget(channel: _channel), ChannelAboutWidget(channel: _channel)];
      }
      return adminTabs;
    }
    if (otherTabs == null) {
      otherTabs = [ChannelPostsWidget(channel: _channel), ChannelAboutWidget(channel: _channel)];
    }
    return otherTabs;
  }

  void subscribe() async {
    Response resp = await ChannelResource.subscribeToChannel(context, _channelId);
    if (resp.statusCode == HttpStatus.ok) {
      FireBaseHandler.subscribeToChannel(_channelId.toString());
      EventManager.notify(Events.CHANNEL_UNSUBSCRIBED);

      setState(() {
        _channel.role = "SUBSCRIBER";
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
}
