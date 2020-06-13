import 'package:cryout_app/screens/home-screen.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BaseScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BaseScreenState();
  }
}

class _BaseScreenState extends State {
  int _selectedIndex = 0;
  Translations _translations;

  final List<Widget> _homeWidgets = [
    HomeScreen(),
    Text("Ask2Pay Page"),
    Text("Transfer Page"),
    Text("Settings Page"),
  ];

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Container(
          child: _homeWidgets.elementAt(_selectedIndex),
        ),
      ),
      /*bottomNavigationBar: Container(
        decoration: BoxDecoration(
         // color: Theme.of(context).bottomAppBarTheme.color,
          shape: BoxShape.rectangle,

        ),
        child: SafeArea(
          maintainBottomViewPadding: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
                gap: 8,
                activeColor: Colors.white,
                iconSize: 24,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                duration: Duration(milliseconds: 600),
                tabBackgroundColor: Colors.grey[800],
                tabs: [
                  GButton(
                    icon: Icons.toc,
                    text: _translations.text("screens.base.home.title"),
                    iconColor: Theme.of(context).iconTheme.color,
                  ),
                  GButton(
                    icon: Icons.call_split,
                    text: _translations.text("screens.common.ask2pay"),
                    iconColor: Theme.of(context).iconTheme.color,
                  ),
                  GButton(
                    icon: Icons.import_export,
                    text: _translations.text("screens.common.send-money"),
                    iconColor: Theme.of(context).iconTheme.color,
                  ),
                  GButton(
                    icon: Icons.settings,
                    text: 'Settings',
                    iconColor: Theme.of(context).iconTheme.color,
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }),
          ),
        ),
      ),*/
    );
  }
}
