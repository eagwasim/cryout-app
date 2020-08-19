import 'package:cryout_app/screens/widgets/created-channels-widget.dart';
import 'package:cryout_app/screens/widgets/subscribed-channels-widget.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/pub-sub.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChannelsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChannelsScreenState();
  }
}

class _ChannelsScreenState extends State with SingleTickerProviderStateMixin, ChangeNotifier {
  Translations _translations;
  TabController _tabController;

  final widgets = [
    SubscribedChannels(),
    CreatedChannels(),
  ];

  @override
  void initState() {
    _tabController = new TabController(vsync: this, length: 2);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).backgroundColor,
            brightness: Theme.of(context).brightness,
            iconTheme: Theme.of(context).iconTheme,
            elevation: 4,
            centerTitle: false,
            title: Text(
              "Safety Channels",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).tabBarTheme.labelColor,
                  unselectedLabelColor: Theme.of(context).tabBarTheme.unselectedLabelColor,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      text: "Subscribed",
                    ),
                    Tab(
                      text: "My Channels",
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: widgets,
          ),
          floatingActionButton: buildSpeedDial(context),
        ),
      ),
    );
  }

  SpeedDial buildSpeedDial(BuildContext context) {
    Brightness brightness = Theme.of(context).brightness;

    Color foreground = brightness == Brightness.dark ? Colors.grey[900] : Colors.white;
    Color background = brightness == Brightness.dark ? Colors.white : Colors.grey[900];

    return SpeedDial(
      overlayColor: brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 24.0),
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(FontAwesomeIcons.feather, color: foreground, size: 16),
          backgroundColor: background,
          onTap: () {
            locator<NavigationService>().navigateTo(Routes.CHANNEL_CREATION_SCREEN).then((value) {
              if (value != null && value) {
                _tabController.animateTo(1);
                EventManager.notify(Events.CHANNEL_CREATED);
              }
            });
          },
          label: 'Create Channel',
          labelStyle: TextStyle(fontWeight: FontWeight.w500, color: foreground),
          labelBackgroundColor: background,
        ),
        SpeedDialChild(
          child: Icon(FontAwesomeIcons.searchPlus, color: foreground, size: 16),
          backgroundColor: background,
          onTap: () {
            locator<NavigationService>().navigateTo(Routes.CHANNEL_SEARCH_SCREEN);
          },
          label: 'Find Channel',
          labelStyle: TextStyle(fontWeight: FontWeight.w500, color: foreground),
          labelBackgroundColor: background,
        ),
      ],
    );
  }

}
