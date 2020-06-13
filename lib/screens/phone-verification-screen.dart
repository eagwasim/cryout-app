import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:international_phone_input/international_phone_input.dart';
import 'package:libphonenumber/libphonenumber.dart';

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
  String _isoCode = "+234";
  String _phoneNUmber;

  Translations _translations;

  void onPhoneNumberChange(String phoneNumber, String internationalizedPhoneNumber, String isoCode, String dialCode) async {
    _isValid = await PhoneNumberUtil.isValidPhoneNumber(phoneNumber: phoneNumber, isoCode: isoCode);

    setState(() {
      _internationalizedPhoneNumber = internationalizedPhoneNumber;
      _isoCode = isoCode;
      _phoneNUmber = phoneNumber;
    });
  }

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
              child: InternationalPhoneInput(
                onPhoneNumberChange: onPhoneNumberChange,
                initialPhoneNumber: _phoneNUmber,
                initialSelection: _isoCode,
                enabledCountries: ["+234"],
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
                            child: Text(_translations.text("screens.common.continue")),
                            onPressed: () async {
                              if (!_isValid) {
                                return;
                              }
                              setState(() {
                                _isProcessing = true;
                              });

                              Response resp = await AccessResource.phoneNumberVerification({'phoneNumber': _internationalizedPhoneNumber, 'channel': 'sms'});

                              if (resp.statusCode != BaseResource.STATUS_OK) {
                                setState(() {
                                  _isProcessing = false;
                                });
                                WidgetUtils.showAlertDialog(context, "Error", "An error occurred while sending confirmation code");
                                return;
                              }

                              await SharedPreferenceUtil.savePhoneNumberForVerification(_internationalizedPhoneNumber);

                              Navigator.of(context).pushNamed(Routes.PHONE_CONFIRMATION_SCREEN);

                              setState(() {
                                _isProcessing = false;
                              });
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
}
