import 'dart:io';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/safety-channel.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

class ChannelPostCreationScreen extends StatefulWidget {
  final SafetyChannel channel;

  const ChannelPostCreationScreen({Key key, this.channel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelPostCreationScreenState(this.channel);
  }
}

class _ChannelPostCreationScreenState extends State {
  Translations _translations;

  TextEditingController _titleController;
  TextEditingController _descriptionController;
  final SafetyChannel _channel;

  String _name = "";
  String _description = "";

  bool _processing = false;

  _ChannelPostCreationScreenState(this._channel);

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }
    if (_titleController == null) {
      _titleController = TextEditingController(text: _name);
    }

    if (_descriptionController == null) {
      _descriptionController = TextEditingController(text: _description);
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
          title: Text(
            _translations.text("screens.channel-post.creation.title"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).iconTheme.color),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                  child: TextField(
                    controller: _titleController,
                    maxLength: 30,
                    maxLengthEnforced: true,
                    decoration: InputDecoration(
                      hintText: "Subject (minimum of 2 characters)",
                    ),
                    onChanged: (text) {
                      _name = text;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                  child: TextField(
                    controller: _descriptionController,
                    minLines: 5,
                    maxLines: 5,
                    enableInteractiveSelection: true,
                    maxLength: 500,
                    maxLengthEnforced: true,
                    onChanged: (text) {
                      _description = text;
                    },
                    decoration: InputDecoration(hintText: "What would you like to share? (minimum of 10 characters)", floatingLabelBehavior: FloatingLabelBehavior.always),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _processing
            ? CircularProgressIndicator()
            : RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(25.0),
                ),
                child: Text(
                  "Publish post",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  _createChannelPost();
                },
              ),
      ),
    );
  }

  void _createChannelPost() async {
    String title = _name.trim();
    String description = _description.trim();

    if (title.isEmpty || title.length < 2 || description.trim().isEmpty || description.length < 10) {
      print("returning....");
      return;
    }

    setState(() {
      _processing = true;
    });

    Response response = await ChannelResource.publishPost(context, _channel.id, {"title": title, "message": description});

    setState(() {
      _processing = false;
    });

    if (response.statusCode != HttpStatus.created) {
      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.general.message"));
      return;
    }

    locator<NavigationService>().pop(result: true);
  }
}
