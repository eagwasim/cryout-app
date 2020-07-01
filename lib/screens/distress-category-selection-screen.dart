import 'dart:convert';

import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/http/distress-resource.dart';
import 'package:cryout_app/models/distress-signal.dart';
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

class DistressCategorySelectionScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DistressCategorySelectionScreenState();
  }
}

class _DistressCategorySelectionScreenState extends State {
  List<String> _categories = ["accident", "fire-outbreak", "robbery", "domestic-abuse", "rape", "suicide", "murder", "health-emergency", "missing-person", "kidnapping", "police-brutality"];

  Translations _translations;
  bool _processing = false;
  Location _location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  @override
  void initState() {
    super.initState();
    _categories.sort();
    _categories.add("other-emergencies");
  }

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    return _processing
        ? WidgetUtils.getLoaderWidget(context, _translations.text("screens.distress-category-selection.sending-distress-signal"))
        : Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).backgroundColor,
              elevation: 0,
              brightness: Theme.of(context).brightness,
              iconTheme: IconThemeData(color: Colors.grey[600]),
              centerTitle: false,
              title: Text(
                _translations.text("screens.distress-category-selection.whats-the-emergency"),
                textAlign: TextAlign.start,
                style: TextStyle(color: Theme.of(context).textTheme.title.color),
              ),
            ),
            body: SafeArea(
                child: ListView.separated(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_translations.text("choices.distress.categories.${_categories[index]}")),
                  onTap: () {
                    _sendDistressSignal(_categories[index]);
                  },
                );
              },
              separatorBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Divider(),
                );
              },
            )),
          );
  }

  void _sendDistressSignal(String selection) async {
    setState(() {
      _processing = true;
    });
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _processing = false;
        });
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();

    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _processing = false;
        });
        return;
      }
    }

    _locationData = await _location.getLocation();

    Response response = await DistressResource.sendDistressCall(context, {"lat": "${_locationData.latitude}", "lon": "${_locationData.longitude}", "details": selection});

    print("RESPONSE ${response.statusCode}");

    if (response.statusCode != BaseResource.STATUS_CREATED) {
      setState(() {
        _processing = false;
      });

      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.distress-category-selection.error-in-sending"));
      return;
    }

    Map<String, dynamic> responseData = jsonDecode(response.body)["data"];

    DistressSignal distressCall = DistressSignal.fromJSON(responseData);

/*    User _user = await SharedPreferenceUtil.currentUser();

    DatabaseReference _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
    await _userPreferenceDatabaseReference.child(PreferenceConstants.CURRENT_DISTRESS_SIGNAL).set(distressCall.toJson());*/

    SharedPreferenceUtil.setCurrentDistressCall(distressCall);

    setState(() {
      _processing = false;
    });

    FireBaseHandler.subscribeToDistressChannelTopic("${distressCall.id}");

    locator<NavigationService>().popAndPushNamed(Routes.VICTIM_DISTRESS_CHANNEL_SCREEN, arguments: distressCall);
  }
}
