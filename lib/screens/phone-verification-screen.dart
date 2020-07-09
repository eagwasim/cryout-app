import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PhoneVerificationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PhoneVerificationScreenState();
  }
}

class _PhoneVerificationScreenState extends State {
  bool _isProcessing = false;
  bool _isValid = false;
  String _internationalizedPhoneNumber = "";
  String initialCountry = 'NL';
  Channel _channel = Channel.SMS;

  PhoneNumber number = PhoneNumber(isoCode: 'NL');
  final TextEditingController _controller = TextEditingController();

  Translations _translations;

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

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
                    Translations.of(context).text("screens.phone.login.title"),
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
                    Translations.of(context).text("screens.phone.login.message"),
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 15),
                  ),
                )),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
              child: InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _internationalizedPhoneNumber = number.phoneNumber;
                },
                onInputValidated: (bool value) {
                  _isValid = value;
                },
                ignoreBlank: true,
                autoValidate: true,
                autoFocus: false,
                errorMessage: _translations.text("screens.phone-verification.error.message"),
                selectorTextStyle: Theme.of(context).textTheme.bodyText1,
                initialValue: number,
                textFieldController: _controller,
                selectorType: PhoneInputSelectorType.DIALOG,
                inputBorder: UnderlineInputBorder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 0, right: 8, top: 8),
              child: Row(
                children: <Widget>[
                  Radio(
                    value: Channel.SMS,
                    groupValue: _channel,
                    activeColor: Theme.of(context).accentColor,
                    onChanged: (Channel value) {
                      setState(() {
                        _channel = value;
                      });
                    },
                  ),
                  Text(
                    _translations.text("screens.phone-verifications.channels.sms"),
                    style: TextStyle(fontSize: 18),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Radio(
                    value: Channel.CALL,
                    groupValue: _channel,
                    activeColor: Theme.of(context).accentColor,
                    onChanged: (Channel value) {
                      setState(() {
                        _channel = value;
                      });
                    },
                  ),
                  Text(
                    _translations.text("screens.phone-verifications.channels.call"),
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _isProcessing
                        ? CircularProgressIndicator()
                        : RaisedButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(25.0),
                            ),
                            child: Text(
                              _translations.text("screens.common.continue"),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              _verifyPhoneNumber();
                            },
                          ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _verifyPhoneNumber() async {
    if (!_isValid) {
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    _internationalizedPhoneNumber = _internationalizedPhoneNumber.replaceAll(new RegExp("[^\+0-9]"), "");

    Response resp = await AccessResource.phoneNumberVerification({'phoneNumber': _internationalizedPhoneNumber, 'channel': _channel.toShortString()});

    if (resp.statusCode != BaseResource.STATUS_OK) {
      setState(() {
        _isProcessing = false;
      });
      WidgetUtils.showAlertDialog(context, "Error", "An error occurred while sending confirmation code");
      return;
    }

    await SharedPreferenceUtil.savePhoneNumberForVerification(_internationalizedPhoneNumber);

    locator<NavigationService>().pushNamed(Routes.PHONE_CONFIRMATION_SCREEN);

    setState(() {
      _isProcessing = false;
    });
  }
}

enum Channel { SMS, CALL }

extension ParseToString on Channel {
  String toShortString() {
    return this.toString().split('.').last;
  }
}
