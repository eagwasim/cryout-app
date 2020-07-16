import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/http/user-resource.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

class UserProfileUpdateScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserProfileUpdateScreenState();
  }
}

class _UserProfileUpdateScreenState extends State {
  Translations _translations;

  TextEditingController _firstNameController;
  TextEditingController _lastNameController;

  GenderConstant _gender = GenderConstant.FEMALE;

  String _firstName;
  String _lastName;

  bool _processing = false;

  User _user;

  @override
  void dispose() {
    super.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

    _firstNameController = new TextEditingController(
      text: _firstName,
    );

    _lastNameController = new TextEditingController(
      text: _lastName,
    );


    if (_user == null) {
      Future<User> userFuture = SharedPreferenceUtil.currentUser();
      userFuture.then((onValue) {
        _user = onValue;

        setState(() {
          _firstName = _user.firstName;
          _lastName = _user.lastName;
        });
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
        centerTitle: false,
        brightness: Theme.of(context).brightness,
        title: Text(
          _translations.text("screens.name-update.title"),
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.headline6,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                          child: Text(_translations.text("screens.name-update.message")),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: TextField(
                        decoration: new InputDecoration(
                          hintText: _translations.text("screens.name-update.hints.first-name"),
                        ),
                        autofocus: true,
                        controller: _firstNameController,
                        keyboardType: TextInputType.text,
                        onChanged: (newValue) {
                          _firstName = newValue;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: TextField(
                        decoration: new InputDecoration(
                          hintText: _translations.text("screens.name-update.hints.last-name"),
                        ),
                        autofocus: true,
                        controller: _lastNameController,
                        keyboardType: TextInputType.text,
                        onChanged: (newValue) {
                          _lastName = newValue;
                        },
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Radio(
                              value: GenderConstant.FEMALE,
                              activeColor: Theme.of(context).accentColor,
                              groupValue: _gender,
                              onChanged: (GenderConstant value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                            Text(
                              _translations.text("screens.name-update.hints.gender.female"),
                              style: TextStyle(fontSize: 18),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: GenderConstant.MALE,
                              groupValue: _gender,
                              activeColor: Theme.of(context).accentColor,
                              onChanged: (GenderConstant value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                            Text(
                              _translations.text("screens.name-update.hints.gender.male"),
                              style: TextStyle(fontSize: 18),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: GenderConstant.NON_BINARY,
                              groupValue: _gender,
                              activeColor: Theme.of(context).accentColor,
                              onChanged: (GenderConstant value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                            Text(
                              _translations.text("screens.name-update.hints.gender.non_binary"),
                              style: TextStyle(fontSize: 18),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: _processing
                        ? CircularProgressIndicator()
                        : RaisedButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(25.0),
                            ),
                            child: Text(
                              _translations.text("screens.common.continue"),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              if (_firstName.trim() != "" && _lastName.trim() != "" ) {
                                setState(() {
                                  _processing = true;
                                });

                                _user.firstName = _firstName.trim().capitalize();
                                _user.lastName = _lastName.trim().capitalize();
                                _user.gender = _gender.toShortString();

                                Response resp = await UserResource.updateUser(context, {
                                  "firstName": _firstName.trim(),
                                  "lastName": _lastName.trim(),
                                  "gender": _gender.toShortString(),
                                });

                                if (resp.statusCode != BaseResource.STATUS_OK) {
                                  setState(() {
                                    _processing = false;
                                  });
                                  WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.general.message"));
                                  return;
                                }

                                await SharedPreferenceUtil.saveUser(_user);

                                locator<NavigationService>().pushNamedAndRemoveUntil(Routes.USER_PROFILE_PHOTO_UPDATE_SCREEN);
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
