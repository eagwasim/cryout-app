import 'dart:io';

import 'package:contact_picker/contact_picker.dart' as cp;
import 'package:cryout_app/http/user-resource.dart';
import 'package:cryout_app/models/emergency-contact.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class EmergencyContactsManagementScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EmergencyContactsManagementScreenState();
  }
}

class _EmergencyContactsManagementScreenState extends State {
  Translations _translations;
  String _internationalizedPhoneNumber = "";
  String _fullName = "";

  final cp.ContactPicker _contactPicker = new cp.ContactPicker();

  TextEditingController _fullNameController;
  TextEditingController _phoneNumberController;

  bool _savingPhoneNumber = false;
  bool _setUpComplete = false;

  User _user;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    _fullNameController = TextEditingController(text: _fullName);
    _phoneNumberController = TextEditingController(text: _internationalizedPhoneNumber);

    if (!_setUpComplete) {
      _setUp();
    }

    return !_setUpComplete
        ? WidgetUtils.getLoaderWidget(context, _translations.text("screens.common.loading"))
        : AnnotatedRegion(
            value: WidgetUtils.updateSystemColors(context),
            child: Scaffold(
              backgroundColor: Theme.of(context).backgroundColor,
              appBar: AppBar(
                iconTheme: Theme.of(context).iconTheme,
                title: Text(
                  _translations.text("screens.emergency-contacts.title"),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.headline1.color),
                ),
                centerTitle: false,
                elevation: 0,
                backgroundColor: Theme.of(context).backgroundColor,
                brightness: Theme.of(context).brightness,
              ),
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: TextField(
                                decoration: new InputDecoration(
                                  hintText: _translations.text("screens.emergency-contacts.full-name"),
                                ),
                                autofocus: false,
                                controller: _fullNameController,
                                keyboardType: TextInputType.text,
                                onChanged: (newValue) {
                                  _fullName = newValue;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: TextField(
                                decoration: new InputDecoration(
                                  hintText: _translations.text("screens.emergency-contacts.phone-number"),
                                ),
                                autofocus: false,
                                controller: _phoneNumberController,
                                keyboardType: TextInputType.phone,
                                onChanged: (newValue) {
                                  _internationalizedPhoneNumber = newValue;
                                },
                              ),
                            ),
                            _savingPhoneNumber
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16, bottom: 16),
                                    child: Center(
                                      child: Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                        ),
                                        height: 20,
                                        width: 20,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: FlatButton.icon(
                                            onPressed: () async {
                                              cp.Contact contact = await _contactPicker.selectContact();

                                              if (contact != null) {
                                                if (contact.phoneNumber.number.startsWith("+")) {
                                                  _internationalizedPhoneNumber = contact.phoneNumber.number;
                                                } else {
                                                  _internationalizedPhoneNumber = await _formatPhoneNumber(contact.phoneNumber.number);
                                                }
                                                setState(() {
                                                  _fullName = contact.fullName;
                                                });
                                              }
                                            },
                                            icon: Icon(
                                              Icons.contact_phone,
                                              color: Colors.grey,
                                            ),
                                            label: Text(
                                              _translations.text("screens.emergency-contacts.pick-from-contacts"),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: FlatButton.icon(
                                            onPressed: () async {
                                              _internationalizedPhoneNumber = await _formatPhoneNumber(_internationalizedPhoneNumber.replaceAll(new RegExp("[^\+0-9]"), ""));

                                              if (_internationalizedPhoneNumber.trim() == "" || _fullName.trim() == "") {
                                                return;
                                              }

                                              if (!_internationalizedPhoneNumber.startsWith("+")) {
                                                WidgetUtils.showAlertDialog(context, _translations.text("screens.emergency-contacts.error.internationalization.title"),
                                                    _translations.text("screens.emergency-contacts.error.internationalization.message"));
                                                return;
                                              }
                                              _savePhoneNumber();
                                            },
                                            icon: Icon(
                                              Icons.save,
                                              color: Theme.of(context).accentColor,
                                            ),
                                            label: Text(
                                              _translations.text("screens.emergency-contacts.save-contact"),
                                              style: TextStyle(
                                                color: Theme.of(context).accentColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
                      child: Text(
                        _translations.text("screens.emergency-contacts.error.contacts.title"),
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                    Flexible(
                        child: FutureBuilder<List<EmergencyContact>>(
                      future: EmergencyContactRepository.all(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data.length == 0) {
                          return _getNoItemsView();
                        }
                        return ListView.builder(itemCount: snapshot.data.length, itemBuilder: (context, index) => _getEmergencyContactView(snapshot.data[index]));
                      },
                    )),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _getNoItemsView() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16, top: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "assets/images/no_emergency_contacts.png",
                      height: 200,
                    ),
                  ),
                ],
              ),
              Text(
                _translations.text("screens.emergency-contacts.empty.message"),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyText2.color.withOpacity(0.8)),
                textAlign: TextAlign.center,
                maxLines: 4,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _formatPhoneNumber(String number) async {
    if (number.trim() == "") {
      return "";
    }

    if (number.startsWith("+")) {
      return number;
    }

    PhoneNumber loggedInUserPhoneNumber = await PhoneNumber.getRegionInfoFromPhoneNumber(_user.phoneNumber);
    PhoneNumber pn = await PhoneNumber.getRegionInfoFromPhoneNumber(number, loggedInUserPhoneNumber.isoCode);
    return pn.phoneNumber;
  }

  Widget _getEmergencyContactView(EmergencyContact emergencyContact) {
    return Dismissible(
      key: Key("${emergencyContact.id}"),
      onDismissed: (direction) {
        EmergencyContactRepository.delete(emergencyContact);
        Future.delayed(Duration(milliseconds: 300), () {
          setState(() {});
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              emergencyContact.fullName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(emergencyContact.phoneNumber),
            Divider()
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoneNumber() async {
    setState(() {
      _savingPhoneNumber = true;
    });

    if (_user.phoneNumber == _internationalizedPhoneNumber) {
      WidgetUtils.showAlertDialog(
        context,
        _translations.text("screens.emergency-contacts.error.phone-number.same-user.title"),
        _translations.text("screens.emergency-contacts.error.phone-number.same-user.message"),
      );
      setState(() {
        _savingPhoneNumber = false;
      });
      return;
    }

    Response response = await UserResource.checkPhoneNumber(context, _internationalizedPhoneNumber);

    if (response.statusCode != HttpStatus.ok) {
      if (response.statusCode == HttpStatus.badRequest) {
        WidgetUtils.showAlertDialog(
          context,
          _translations.text("screens.emergency-contacts.error.phone-number.not-registered.title"),
          _translations.text("screens.emergency-contacts.error.phone-number.not-registered.message"),
        );
      } else {
        WidgetUtils.showAlertDialog(
          context,
          _translations.text("screens.common.error.general.title"),
          _translations.text("screens.common.error.general.message"),
        );
      }
      setState(() {
        _savingPhoneNumber = false;
      });
      return;
    }

    EmergencyContact emergencyContact = EmergencyContact(fullName: _fullName, phoneNumber: _internationalizedPhoneNumber, id: new DateTime.now().millisecondsSinceEpoch);

    await EmergencyContactRepository.save(emergencyContact);
    setState(() {
      //_emergencyContacts.insert(0, emergencyContact);
      _savingPhoneNumber = false;
      _fullName = "";
      _internationalizedPhoneNumber = "";
    });
  }

  Future<void> _setUp() async {
    _user = await SharedPreferenceUtil.currentUser();

    setState(() {
      _setUpComplete = true;
    });
  }
}
