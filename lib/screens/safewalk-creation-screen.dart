import 'package:cryout_app/models/emergency-contact.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
                    padding: const EdgeInsets.only(left: 16.0, bottom: 16),
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
                    padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8, left: 16),
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
                return ListView.builder(itemCount: snapshot.data.length, itemBuilder: (context, index) => _getEmergencyContactView(snapshot.data[index]));
              },
            )),
          ],
        ),
      ),
      floatingActionButton: Padding(
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

    if(_selectedPhoneNumbers.isEmpty){
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


  }
}
