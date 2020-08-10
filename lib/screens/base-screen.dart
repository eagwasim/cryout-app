import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'home-screen.dart';

class BaseScreen extends StatefulWidget {
  final int initialScreen;

  const BaseScreen({Key key, this.initialScreen}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BaseScreenState(initialScreen);
  }
}

class NavScreenHolder {
  final Widget screen;
  final String title;
  final IconData icon;

  NavScreenHolder(this.screen, this.title, this.icon);
}

class _BaseScreenState extends State {
  int _selectedScreen;
  Translations _translations;

  final List<NavScreenHolder> _screens = [
    NavScreenHolder(HomeScreen(), "screens.base.nav.home", FontAwesomeIcons.userShield),
    NavScreenHolder(Center(child: Text("Page Two"),), "screens.base.nav.channels", FontAwesomeIcons.rss),
  ];

  _BaseScreenState(this._selectedScreen);

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: _screens.elementAt(_selectedScreen).screen,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // color: Theme.of(context).bottomAppBarTheme.color,
          shape: BoxShape.rectangle,
          border: Border(top: BorderSide(color: Colors.grey.withAlpha(100)))
        ),
        child: SafeArea(
          maintainBottomViewPadding: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
                gap: 16,
                activeColor: Colors.white,
                iconSize: 24,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                //duration: Duration(milliseconds: 400),
                tabBackgroundColor: Colors.grey[900],
                tabs: _screens
                    .map(
                      (e) => GButton(
                        icon: e.icon,
                        text: _translations.text(e.title),
                        iconColor: Theme.of(context).iconTheme.color,
                      ),
                    ).toList(),
                selectedIndex: _selectedScreen,
                onTabChange: (index) async{
                  setState(() {
                    _selectedScreen = index;
                  });
                }),
          ),
        ),
      ),
    );
  }
}
