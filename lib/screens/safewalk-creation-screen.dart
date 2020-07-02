import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/safe-walk-resource.dart';
import 'package:cryout_app/models/emergency-contact.dart';
import 'package:cryout_app/models/safe-walk.dart';
import 'package:cryout_app/utils/background_location_update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';

class SafeWalkCreationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SafeWalkCreationScreenState();
  }
}

class _SafeWalkCreationScreenState extends State {
  Set<EmergencyContact> _selectedPhoneNumbers = {};

  String _destination = "";

  bool _isProcessing = false;

  TextEditingController _destinationController;
  Translations _translations;

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    _destinationController = TextEditingController(text: _destination);

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          _translations.text("screens.safe-walk-creation.title"),
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
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: new InputDecoration(
                  hintText: _translations.text("screens.safe-walk-creation.destination"),
                ),
                autofocus: false,
                controller: _destinationController,
                keyboardType: TextInputType.text,
                onChanged: (newValue) {
                  _destination = newValue;
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 16, top: 8),
                    child: Text(
                      _translations.text("screens.safe-walk-creation.select-contacts"),
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    locator<NavigationService>().pushNamed(Routes.MANAGE_EMERGENCY_CONTACTS_SCREEN).then((value) => setState(() {}));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 0, bottom: 8, left: 16),
                    child: Text(
                      _translations.text("screens.safe-walk-creation.manage"),
                      style: TextStyle(fontWeight: Theme.of(context).textTheme.caption.fontWeight, fontSize: Theme.of(context).textTheme.caption.fontSize, color: Theme.of(context).accentColor),
                    ),
                  ),
                )
              ],
            ),
            Flexible(
                child: FutureBuilder<List<EmergencyContact>>(
              future: EmergencyContactRepository.all(),
              builder: (context, snapshot) {
                if(!snapshot.hasData || snapshot.data.length == 0){
                  return _getNoItemsView();
                }
                return ListView.builder(itemCount: snapshot.data.length, itemBuilder: (context, index) => _getEmergencyContactView(snapshot.data[index]));
              },
            )),
          ],
        ),
      ),
      floatingActionButton: _isProcessing
          ? CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RaisedButton.icon(
                elevation: 4,
                onPressed: () {
                  _beginSafeWalk();
                },
                icon: Icon(
                  Icons.directions_walk,
                  color: Colors.white,
                ),
                label: Text(
                  _translations.text("screens.safe-walk-creation.action"),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.all(16),
              ),
            ),
    );
  }

  Widget _getEmergencyContactView(EmergencyContact emergencyContact) {
    return CheckboxListTile(
      activeColor: Theme.of(context).accentColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            emergencyContact.fullName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            emergencyContact.phoneNumber,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      value: _selectedPhoneNumbers.contains(emergencyContact),

      onChanged: (newValue) {
        setState(() {
          if (newValue) {
            _selectedPhoneNumbers.add(emergencyContact);
          } else {
            _selectedPhoneNumbers.remove(emergencyContact);
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading, //  <-- leading Checkbox
    );
  }

  Location _location = new Location();

  void _beginSafeWalk() async {
    if (_destination.trim() == "") {
      WidgetUtils.showAlertDialog(context, _translations.text("screens.safe-walk-creation.error.destination.title"), _translations.text("screens.safe-walk-creation.error.destination.message"));
      return;
    }

    if (_selectedPhoneNumbers.isEmpty) {
      WidgetUtils.showAlertDialog(context, _translations.text("screens.safe-walk-creation.error.contacts.title"), _translations.text("screens.safe-walk-creation.error.contacts.message"));
      return;
    }

    bool _serviceEnabled = await _location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    PermissionStatus _permissionGranted = await _location.hasPermission();

    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    Response response = await SafeWalkResource.sendSafeWalk(context, {"destination": _destination, "emergencyContacts": _selectedPhoneNumbers.map((e) => e.phoneNumber).toList()});

    if (response.statusCode != HttpStatus.created) {
      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.general.message"));
      return;
    }

    SafeWalk safeWalk = SafeWalk(id: jsonDecode(response.body)['data']['safeWalkId'], destination: _destination);

    await SharedPreferenceUtil.setSafeWalk(safeWalk);

    setState(() {
      _isProcessing = false;
    });

    FireBaseHandler.subscribeSafeWalkChannelTopic("${safeWalk.id}");

    BackgroundLocationUpdate.startLocationTracking();

    SharedPreferenceUtil.startedSafeWalk();

    locator<NavigationService>().popAndPushNamed(Routes.SAFE_WALK_WALKER_SCREEN, arguments: safeWalk);
  }
  Widget _getNoItemsView() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16, top: 60.0),
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


}
