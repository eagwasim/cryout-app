import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:introduction_screen/introduction_screen.dart';

class AppIntroductionScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppIntroductionScreenState();
  }
}

class _AppIntroductionScreenState extends State {
  List<PageViewModel> pages;

  @override
  Widget build(BuildContext context) {
    if (pages == null) {
      pages = [
        PageViewModel(
          image: _fromImage("assets/images/intro_stage_one.png"),
          title: Translations.of(context).text('screens.introduction.page.one.title'),
          body: Translations.of(context).text('screens.introduction.page.one.message'),
        ),
        PageViewModel(
          image: _fromImage("assets/images/intro_stage_two.png"),
          title: Translations.of(context).text('screens.introduction.page.two.title'),
          body: Translations.of(context).text('screens.introduction.page.two.message'),
        ),
        PageViewModel(
          image: _fromImage("assets/images/intro_stage_three.png"),
          title: Translations.of(context).text('screens.introduction.page.three.title'),
          body: Translations.of(context).text('screens.introduction.page.three.message'),
        ),
        PageViewModel(
          image: _fromImage("assets/images/intro_stage_four.png"),
          title: Translations.of(context).text('screens.introduction.page.four.title'),
          body: Translations.of(context).text('screens.introduction.page.four.message'),
        ),
      ];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        brightness: Theme.of(context).brightness,
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: IntroductionScreen(
          dotsDecorator: DotsDecorator(activeColor: Theme.of(context).accentColor),
          pages: pages,
          globalBackgroundColor: Theme.of(context).backgroundColor,
          done: Text(Translations.of(context).text("screens.common.next"), style: TextStyle(fontWeight: FontWeight.w600)),
          showSkipButton: true,
          skip: Text(Translations.of(context).text("screens.common.skip"), style: TextStyle(fontWeight: FontWeight.w600)),
          onSkip: () {
            locator<NavigationService>().pushNamedAndRemoveUntil(Routes.PHONE_VERIFICATION_SCREEN);
          },
          onDone: () {
            locator<NavigationService>().pushNamedAndRemoveUntil(Routes.PHONE_VERIFICATION_SCREEN);
          },
          dotsFlex: 1,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );
  }

  static Widget _fromImage(String imageAsset) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          width: 200,
        ),
      ),
    );
  }
}
