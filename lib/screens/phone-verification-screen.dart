import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/access-resource.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
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
                              if (_channel == Channel.CALL) {
                                _verifyPhoneNumber();
                              } else {
                                _verifyPhoneNumberFirebase();
                              }
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

  void _verifyPhoneNumberFirebase() async {
    if (!_isValid) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    _internationalizedPhoneNumber = _internationalizedPhoneNumber.replaceAll(new RegExp("[^\+0-9]"), "");

    final FirebaseAuth _auth = FirebaseAuth.instance;

    await _auth.verifyPhoneNumber(
      phoneNumber: _internationalizedPhoneNumber,
      timeout: Duration(seconds: 0),
      verificationCompleted: (AuthCredential auth) {
        _auth
            .signInWithCredential(auth)
            .then((result) => () {
                  _loginUser(result);
                })
            .catchError((e) {
          _showError(e.message);
        });
      },
      verificationFailed: (AuthException authException) {
        _showError(authException.message);
      },
      codeSent: (String verificationId, [int forceResendingToken]) {
        _verifyOTP(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isProcessing = false;
        });
        locator<NavigationService>().pushNamed(Routes.FIREBASE_SMS_CODE_CONFIRMATION_SCREEN, arguments: verificationId);
      },
    );
  }

  TextEditingController _firebaseSMSCodeController = TextEditingController(text: "");

  void _verifyOTP(String verificationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_translations.text("screens.phone.confirmation.message")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: new InputDecoration(
                hintText: _translations.text("screens.phone-verifications.enter-code.hint"),
              ),
              autofocus: true,
              controller: _firebaseSMSCodeController,
            ),
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(_translations.text("screens.common.confirm")),
            textColor: Colors.white,
            color: Theme.of(context).accentColor,
            onPressed: () {
              FirebaseAuth auth = FirebaseAuth.instance;
              String smsCode = _firebaseSMSCodeController.text.trim();
              AuthCredential _credential = PhoneAuthProvider.getCredential(verificationId: verificationId, smsCode: smsCode);
              auth.signInWithCredential(_credential).then((AuthResult result) {
                _loginUser(result);
              }).catchError(
                (e) {
                  Navigator.of(context).pop();
                  _showError(e.message);
                },
              );
            },
          )
        ],
      ),
    );
  }

  void _showError(String message) {
    WidgetUtils.showAlertDialog(context, "", message);
    setState(() {
      _isProcessing = false;
    });
  }

  void _loginUser(AuthResult authResult) async {
    IdTokenResult idTokenResult = await authResult.user.getIdToken(refresh: false);

    Response resp = await AccessResource.loginUserByFirebaseToken({'token': idTokenResult.token});

    if (resp.statusCode == HttpStatus.forbidden) {
      setState(() {
        _isProcessing = false;
      });
      WidgetUtils.showAlertDialog(
        context,
        'Account suspended!',
        'Your account is currently suspended.',
      );
      return;
    }

    if (resp.statusCode != HttpStatus.ok) {
      setState(() {
        _isProcessing = false;
      });
      WidgetUtils.showAlertDialog(
        context,
        _translations.text("screens.common.error.general.title"),
        _translations.text("screens.common.error.general.message"),
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

    setState(() {
      _isProcessing = false;
    });

    FireBaseHandler.subscribeToUserTopic(user.id);

    locator<NavigationService>().pushNamedAndRemoveUntil(await Routes.initialRoute());
  }
}

enum Channel { SMS, CALL }

extension ParseToString on Channel {
  String toShortString() {
    return this.toString().split('.').last;
  }
}
