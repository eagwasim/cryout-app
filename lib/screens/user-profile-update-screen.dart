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
import 'package:intl/intl.dart';

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
  TextEditingController _emailAddressController;
  TextEditingController _dateOfBirthController;

  GenderConstant _gender = GenderConstant.FEMALE;

  String _firstName;
  String _lastName;
  String _emailAddress;
  String _dateOfBirth;

  DateTime _selectedDateOfBirth;

  bool _processing = false;

  User _user;

  @override
  void dispose() {
    super.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailAddressController.dispose();
    _dateOfBirthController.dispose();
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

    _emailAddressController = new TextEditingController(
      text: _emailAddress,
    );

    _dateOfBirthController = new TextEditingController(
      text: _dateOfBirth,
    );

    if (_user == null) {
      Future<User> userFuture = SharedPreferenceUtil.currentUser();
      userFuture.then((onValue) {
        _user = onValue;

        setState(() {
          _firstName = _user.firstName;
          _lastName = _user.lastName;
          _emailAddress = _user.emailAddress;
        });
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
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
                          child: Text("Updating this info later is currently not possible"),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        decoration: new InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).accentColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 1.0),
                          ),
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
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        decoration: new InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).accentColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 1.0),
                          ),
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        decoration: new InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).accentColor, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          hintText: _translations.text("screens.name-update.hints.email"),
                        ),
                        autofocus: true,
                        controller: _emailAddressController,
                        keyboardType: TextInputType.text,
                        onChanged: (newValue) {
                          _emailAddress = newValue;
                        },
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Radio(
                              value: GenderConstant.FEMALE,
                              groupValue: _gender,
                              onChanged: (GenderConstant value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                            Text(
                              "Female",
                              style: TextStyle(fontSize: 18),
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: GenderConstant.MALE,
                              groupValue: _gender,
                              onChanged: (GenderConstant value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                            Text(
                              "Male",
                              style: TextStyle(fontSize: 18),
                            )
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: InkWell(
                        onTap: () {
                          launchDatePicker();
                        },
                        child: TextField(
                          enabled: false,
                          decoration: new InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).accentColor, width: 1.0),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 1.0),
                            ),
                            hintText: _translations.text("screens.name-update.hints.date-of-birth"),
                          ),
                          autofocus: true,
                          controller: _dateOfBirthController,
                          keyboardType: TextInputType.text,
                          onChanged: (newValue) {
                            _dateOfBirth = newValue;
                          },
                        ),
                      ),
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
                              if (_firstName.trim() != "" && _lastName.trim() != "" && _emailAddress.trim() != null && _emailAddress.trim().contains("@") && _dateOfBirth != null) {
                                setState(() {
                                  _processing = true;
                                });

                                _user.firstName = _firstName.trim();
                                _user.lastName = _lastName.trim();
                                _user.emailAddress = _emailAddress.trim();
                                _user.dateOfBirth = _dateOfBirth;
                                _user.gender = _gender.toShortString();

                                Response resp = await UserResource.updateUser(context, {
                                  "firstName": _firstName.trim(),
                                  "lastName": _lastName.trim(),
                                  "emailAddress": _emailAddress.toLowerCase().trim(),
                                  "dateOfBirth": _dateOfBirth.toLowerCase().trim(),
                                  "gender": _gender.toShortString(),
                                });

                                if (resp.statusCode != BaseResource.STATUS_OK) {
                                  setState(() {
                                    _processing = false;
                                  });
                                  WidgetUtils.showAlertDialog(context, "Error", "An error occurred while updating");
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

  var formatter = new DateFormat('MM/dd/yyyy');

  void launchDatePicker() async {
    final datePick = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth == null ? new DateTime(DateTime.now().year - 18) : _selectedDateOfBirth,
      firstDate: new DateTime(DateTime.now().year - 100),
      lastDate: new DateTime(DateTime.now().year - 9),
    );

    if (datePick != null) {
      setState(() {
        _selectedDateOfBirth = datePick;
        _dateOfBirth = formatter.format(datePick);
      });
    }
  }
}
