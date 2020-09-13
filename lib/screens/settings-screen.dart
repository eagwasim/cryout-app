import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryout_app/http/base-resource.dart';
import 'package:cryout_app/http/samaritan-resource.dart';
import 'package:cryout_app/main.dart';
import 'package:cryout_app/models/emergency-contact.dart';
import 'package:cryout_app/models/my-channel.dart';
import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/models/received-safe-walk.dart';
import 'package:cryout_app/models/subscribed-channel.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/screens/static-page-screen.dart';
import 'package:cryout_app/utils/background-location-update.dart';
import 'package:cryout_app/utils/firebase-handler.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/preference-constants.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:package_info/package_info.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State {
  User _user;
  Translations _translations;
  PackageInfo _packageInfo;
  DatabaseReference _userPreferenceDatabaseReference;
  bool _samaritanModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          iconTheme: Theme.of(context).iconTheme,
          elevation: 2,
          title: Text(
            "Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
          ),
          centerTitle: false,
          brightness: Theme.of(context).brightness,
        ),
        body: SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: _user == null ? "https://via.placeholder.com/44x44?text=." : _user.profilePhoto,
                    height: 28,
                    width: 28,
                  ),
                ),
                title: Text('Your info'),
                subtitle: Text(_user == null ? "" : _user.fullName() + " • " + _translations.text("screens.name-update.hints.gender." + _user.gender.toLowerCase()) + " • " + _user.phoneNumber),
              ),
              Divider(
                indent: 75,
              ),
              ListTile(
                leading: Padding(
                  padding: EdgeInsets.all(8),
                ),
                title: Text("Samaritan mode"),
                subtitle: Text("Enable this mode to listen for distress signals around you."),
                trailing: Switch(
                  activeColor: Theme.of(context).accentColor,
                  value: _samaritanModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _samaritanModeEnabled = value;
                    });
                    updateSamaritanMode(context, value);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Divider(
                indent: 75,
              ),
              ListTile(
                leading: Icon(
                  FontAwesomeIcons.userFriends,
                  size: 20,
                ),
                title: Text("Emergency contacts"),
                subtitle: Text("Manage your emergency contacts"),
                trailing: Icon(
                  FontAwesomeIcons.edit,
                  size: 14,
                ),
                onTap: () {
                  locator<NavigationService>().pushNamed(Routes.MANAGE_EMERGENCY_CONTACTS_SCREEN);
                },
              ),
              Divider(
                indent: 75,
              ),
              ListTile(
                leading: Padding(
                  padding: EdgeInsets.all(8),
                ),
                title: Text("Terms of service"),
                trailing: Icon(
                  FontAwesomeIcons.externalLinkAlt,
                  size: 14,
                ),
                onTap: () {
                  locator<NavigationService>().pushNamed(Routes.STATIC_WEB_PAGE_VIEW_SCREEN, arguments: WebPageModel("Terms of Service", "${BaseResource.BASE_URL}/pages/terms-of-service"));
                },
              ),
              ListTile(
                leading: Padding(
                  padding: EdgeInsets.all(8),
                ),
                title: Text("Privacy policy"),
                trailing: Icon(
                  FontAwesomeIcons.externalLinkAlt,
                  size: 14,
                ),
                onTap: () {
                  locator<NavigationService>().pushNamed(Routes.STATIC_WEB_PAGE_VIEW_SCREEN, arguments: WebPageModel("Privacy Policy", "${BaseResource.BASE_URL}/pages/privacy-policy"));
                },
              ),
              Divider(
                indent: 75,
              ),
              ListTile(
                leading: Padding(
                  padding: EdgeInsets.all(8),
                ),
                title: Text("Version"),
                subtitle: Text(_packageInfo == null ? "" : _packageInfo.version),
              ),
              Divider(
                indent: 75,
              ),
              ListTile(
                leading:Icon(
                  FontAwesomeIcons.signOutAlt,
                  size: 20,
                ),
                title: Text("Log out"),
                onTap: () {
                  _showLogOutDialog();
                },

              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 1),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(_translations.text("screens.home.log-out")),
          content: Text(_translations.text("screens.home.log-out.details")),
          actions: <Widget>[
            FlatButton(
              child: Text(_translations.text("screens.common.cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(
                _translations.text("screens.home.log-out"),
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logOutOfApplication();
              },
            )
          ],
        );
      },
    );
  }

  void _logOutOfApplication() async {
    await FireBaseHandler.unsubscribeFromAllTopics();

    await ReceivedDistressSignalRepository.clear();
    await ReceivedSafeWalkRepository.clear();
    await EmergencyContactRepository.clear();
    await SubscribedChannelRepository.clear();
    await MyChannelRepository.clear();

    await BackgroundLocationUpdate.stopLocationTracking();

    await SharedPreferenceUtil.clear();

    await FirebaseAuth.instance.signOut();

    locator<NavigationService>().pushNamedAndRemoveUntil(Routes.PHONE_VERIFICATION_SCREEN);
  }

  void _initialize() async {
    if (_user == null) {
      _user = await SharedPreferenceUtil.currentUser();
    }

    if (_userPreferenceDatabaseReference == null) {
      _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
      _userPreferenceDatabaseReference.keepSynced(true);
    }

    var dbSS = await _userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).once();
    _samaritanModeEnabled = dbSS == null || dbSS.value == null ? false : dbSS.value;

    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }

    setState(() {});
  }

  void updateSamaritanMode(BuildContext context, bool _enabled) async {
    Response resp = await SamaritanResource.updateSamaritanMode(context, {"samaritanModeEnabled": _enabled});

    if (resp.statusCode != 200) {
      _enabled = !_enabled;
    }

    if (_userPreferenceDatabaseReference == null) {
      _userPreferenceDatabaseReference = database.reference().child('users').reference().child("${_user.id}").reference().child("preferences").reference();
    }

    _userPreferenceDatabaseReference.child(PreferenceConstants.SAMARITAN_MODE_ENABLED).set(_enabled);

    setState(() {
      _samaritanModeEnabled = _enabled;
    });

    _updateLocationTrackingStatus();
  }

  void _updateLocationTrackingStatus() async {
    if (_samaritanModeEnabled != null && _samaritanModeEnabled) {
      FireBaseHandler.subscribeToSamaritanTopic(_user.id);
      BackgroundLocationUpdate.startLocationTracking();
    } else if (_samaritanModeEnabled != null && !_samaritanModeEnabled) {
      if (!await SharedPreferenceUtil.isSafeWalking()) {
        BackgroundLocationUpdate.stopLocationTracking();
      }
      FireBaseHandler.unSubscribeToSamaritanTopic(_user.id);
    }
  }
}
