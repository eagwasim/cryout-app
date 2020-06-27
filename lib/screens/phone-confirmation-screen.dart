import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';

class PhoneConfirmationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PhoneConfirmationScreenState();
  }
}

class _PhoneConfirmationScreenState extends State {
  TextEditingController controller = TextEditingController(text: "");
  Translations _translations;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

    if (_isProcessing) {
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.phone.login.confirmation.message"));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
        brightness: Theme.of(context).brightness,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8),
                  child: Text(
                    Translations.of(context).text("screens.phone.confirmation.title"),
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                )),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
                  child: Text(
                    Translations.of(context).text("screens.phone.confirmation.message"),
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 15),
                  ),
                )),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
            ),
            PinCodeTextField(
              autofocus: true,
              controller: controller,
              hideCharacter: false,
              highlight: true,
              highlightColor: Colors.grey[700],
              defaultBorderColor: Colors.grey,
              hasTextBorderColor: Colors.deepOrange,
              maxLength: 4,
              onTextChanged: (text) {},
              onDone: (text) async {
                setState(() {
                  _isProcessing = true;
                });

                String phoneNumber = await SharedPreferenceUtil.getPhoneNumberForVerification();

                Response resp = await AccessResource.phoneNumberConfirmation({"phoneNumber": phoneNumber, "code": text});

                setState(() {
                  _isProcessing = false;
                });

                if (resp.statusCode == HttpStatus.badRequest) {
                  WidgetUtils.showAlertDialog(
                    context,
                    _translations.text("screens.phone.confirmation.error.invalid_code.title"),
                    _translations.text("screens.phone.confirmation.error.invalid_code.message"),
                  );
                  return;
                }

                if (resp.statusCode == HttpStatus.forbidden) {
                  WidgetUtils.showAlertDialog(
                    context,
                    'Account suspended!',
                    'Your account is currently suspended.',
                  );
                  return;
                }

                if (resp.statusCode != HttpStatus.ok) {
                  WidgetUtils.showAlertDialog(
                    context,
                    _translations.text("common.error.unknown.title"),
                    _translations.text("common.error.unknown.message"),
                  );
                  return;
                }

                Map<String, dynamic> responseData = jsonDecode(resp.body)["data"];

                String token = responseData["token"];
                String refreshToken = responseData["refreshToken"];

                Map<String, dynamic> userData = responseData["user"];
                List<dynamic> userPreferencesResponse = responseData["preferences"];

                User user = User.fromJson(userData);

                await SharedPreferenceUtil.saveUser(user);
                await SharedPreferenceUtil.saveToken(token);
                await SharedPreferenceUtil.saveRefreshToken(refreshToken);

                if (userPreferencesResponse.isNotEmpty) {
                  for (int index = 0; index < userPreferencesResponse.length; index++) {
                    await SharedPreferenceUtil.setString(userPreferencesResponse[index]["name"], userPreferencesResponse[index]["value"]);
                  }
                }

                FireBaseHandler.subscribeToUserTopic(user.id);

                locator<NavigationService>().pushNamedAndRemoveUntil(await Routes.initialRoute());
              },
              wrapAlignment: WrapAlignment.spaceAround,
              pinBoxDecoration: ProvidedPinBoxDecoration.defaultPinBoxDecoration,
              pinTextStyle: TextStyle(fontSize: 30.0),
              pinTextAnimatedSwitcherTransition: ProvidedPinBoxTextAnimation.scalingTransition,
              pinTextAnimatedSwitcherDuration: Duration(milliseconds: 300),
              highlightAnimationBeginColor: Colors.black,
              highlightAnimationEndColor: Colors.white12,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
