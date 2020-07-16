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
  TextEditingController _firebaseSMSCodeController = TextEditingController(text: "");

  _PhoneConfirmationFirebaseScreenState(this._verificationId);

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
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8),
              child: TextField(
                decoration: new InputDecoration(
                  hintText: _translations.text("screens.phone-verifications.enter-code.hint"),
                ),
                autofocus: true,
                controller: _firebaseSMSCodeController,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isProcessing
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
                _preLogin();
              },
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
