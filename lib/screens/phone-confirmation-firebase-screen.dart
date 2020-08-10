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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneConfirmationFirebaseScreen extends StatefulWidget {
  final String verificationId;

  const PhoneConfirmationFirebaseScreen({Key key, this.verificationId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PhoneConfirmationFirebaseScreenState(this.verificationId);
  }
}

class _PhoneConfirmationFirebaseScreenState extends State {
  final String _verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Translations _translations;
  bool _isProcessing = false;
  String currentText;
  TextEditingController _firebaseSMSCodeController;

  _PhoneConfirmationFirebaseScreenState(this._verificationId);

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);
    _firebaseSMSCodeController = TextEditingController(text: currentText);

    if (_isProcessing) {
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.phone.login.confirmation.message"));
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          elevation: 0,
          brightness: Theme.of(context).brightness,
          iconTheme: Theme.of(context).iconTheme,
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
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24),
                child: PinCodeTextField(
                  length: 6,
                  obsecureText: false,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.circle,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: 40,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                    activeFillColor: Colors.white,
                  ),
                  animationDuration: Duration(milliseconds: 300),
                  enableActiveFill: false,
                  autoFocus: true,
                  controller: _firebaseSMSCodeController,
                  backgroundColor: Theme.of(context).backgroundColor,
                  textInputType: TextInputType.number,
                  onCompleted: (v) {
                    currentText = v;
                    _preLogin();
                  },
                  onChanged: (value) {
                    print(value);
                    setState(() {
                      currentText = value;
                    });
                  },
                  beforeTextPaste: (text) {
                    //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                    //but you can show anything you want here, like your pop up saying wrong paste format or etc
                    return true;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _preLogin() {
    setState(() {
      _isProcessing = true;
    });
    String smsCode = _firebaseSMSCodeController.text.trim();

    AuthCredential _credential = PhoneAuthProvider.getCredential(verificationId: _verificationId, smsCode: smsCode);
    _auth.signInWithCredential(_credential).then((AuthResult result) {
      _loginUser(result);
    }).catchError(
      (e) {
        _showError(e.message);
      },
    );
  }

  void _showError(String message) {
    setState(() {
      currentText = "";
      _isProcessing = false;
    });

    WidgetUtils.showAlertDialog(context, "", message);
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
    String notificationToken = responseData["notificationToken"];

    Map<String, dynamic> userData = responseData["user"];
    List<dynamic> userPreferencesResponse = responseData["preferences"];

    User user = User.fromJson(userData);

    await SharedPreferenceUtil.saveUser(user);
    await SharedPreferenceUtil.saveToken(token);
    await SharedPreferenceUtil.saveRefreshToken(refreshToken);
    // Remove user
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    firebaseUser.delete();
    // Sign them in with our token
    await _auth.signInWithCustomToken(token: notificationToken);

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
