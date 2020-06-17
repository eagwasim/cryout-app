import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:flutter/widgets.dart';

class SplashScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    Future.sync(() async {
      locator<NavigationService>().pushReplacementNamed(await Routes.initialRoute());
    });
    return Container();
  }
}
