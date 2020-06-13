import 'package:cryout_app/utils/routes.dart';
import 'package:flutter/widgets.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.sync(() async {
      Navigator.of(context).pushReplacementNamed(await Routes.initialRoute());
    });
    return Container();
  }
}
