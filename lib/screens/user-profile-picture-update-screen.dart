import 'dart:io';

import 'package:cryout_app/http/user-resource.dart';
import 'package:cryout_app/models/user.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/shared-preference-util.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class UserProfilePictureUpdateScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProfilePictureUpdateScreenState();
  }
}

class _ProfilePictureUpdateScreenState extends State {
  bool _isProcessing = false;
  Translations _translations;

  File _imageFile;
  User _user;

  /// Cropper plugin
  Future<void> _cropImage(BuildContext context, String file) async {
    File cropped = await ImageCropper.cropImage(
        sourcePath: file,
        maxWidth: 250,
        maxHeight: 250,
        cropStyle: CropStyle.rectangle,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        compressFormat: ImageCompressFormat.jpg,
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Theme
                .of(context)
                .accentColor,
            toolbarWidgetColor: Theme
                .of(context)
                .dividerColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Crop',
        ));
    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  /// Select an image via gallery or camera
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    PickedFile selected = await ImagePicker().getImage(source: source, maxHeight: 250, maxWidth: 250);
    if (selected == null) {
      return;
    }
    _cropImage(context, selected.path);
  }

  @override
  Widget build(BuildContext context) {
    _translations = Translations.of(context);

    if (_isProcessing) {
      return WidgetUtils.getLoaderWidget(context, _translations.text("screens.profile-photo-update.processing"));
    }

    Future<User> user = SharedPreferenceUtil.currentUser();
    user.then((value) => _user = value);

    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .backgroundColor,
        elevation: 0,
        brightness: Theme
            .of(context)
            .brightness,
        iconTheme: Theme
            .of(context)
            .iconTheme,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  child: _imageFile == null
                      ? _circularImage(Icon(
                    Icons.image,
                    size: 250,
                    color: Colors.blueAccent,
                  ))
                      : _circularImage(Image.file(
                    _imageFile,
                    height: 200,
                  )),
                  onTap: () {
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
                      child: Text(
                        Translations.of(context).text("screens.profile-photo-update.subtitle"),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    )),
              ],
            ),
            Expanded(
              child: Container(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FlatButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(25.0),
                        side: BorderSide(
                          color: Theme
                              .of(context)
                              .accentColor,
                        ),
                      ),
                      child: Text(_translations.text("screens.common.done")),
                      onPressed: () async {
                        if (_imageFile == null) {
                          return;
                        }
                        setState(() {
                          _isProcessing = true;
                        });
                        _uploadImage(context, _imageFile);
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

  Widget _circularImage(Widget image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: image,
    );
  }

  void _uploadImage(BuildContext context, File file) async {
    String filename = _user.id + ".jpg";
    try {
      StorageReference storageReference = FirebaseStorage.instance.ref().child("images/$filename");

      final StorageUploadTask uploadTask = storageReference.putFile(file);
      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      final String url = (await downloadUrl.ref.getDownloadURL());

      if (url != null) {
        _save(context, url);
      } else {
        setState(() {
          _isProcessing = false;
        });
        WidgetUtils.showAlertDialog(context, _translations.text("common.error.unknown.title"), _translations.text("common.error.unknown.message"));
      }
    } on Exception catch (e) {
      print(e);
      setState(() {
        _isProcessing = false;
      });
      WidgetUtils.showAlertDialog(context, _translations.text("common.error.unknown.title"), _translations.text("common.error.unknown.message"));
    }
  }

  void _save(BuildContext context, String profilePicture) async {
    Map<String, String> payload = {"profilePhoto": profilePicture};

    Response response = await UserResource.updateUser(context, payload);

    if (response.statusCode == 200) {
      _user.profilePhoto = profilePicture;

      await SharedPreferenceUtil.saveUser(_user);

      Navigator.of(context).pushNamedAndRemoveUntil(Routes.BASE_SCREEN, (Route<dynamic> route) => false);
    } else {
      print("Saving Failed ${response.statusCode}");
      setState(() {
        _isProcessing = false;
      });
      WidgetUtils.showAlertDialog(context, _translations.text("common.error.unknown.title"), _translations.text("common.error.unknown.message"));
    }
  }
}
