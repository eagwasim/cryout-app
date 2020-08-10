import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/widgets.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.sync(() async {
      locator<NavigationService>().pushNamedAndRemoveUntil(await Routes.initialRoute());
    });
    return AnnotatedRegion(value: WidgetUtils.updateSystemColors(context), child: Container());
  }
}
