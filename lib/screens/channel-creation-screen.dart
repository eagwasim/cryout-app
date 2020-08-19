
import 'dart:io';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/translations.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

class ChannelCreationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChannelCreationScreenState();
  }
}

class _ChannelCreationScreenState extends State {
  Translations _translations;

  TextEditingController _titleController;
  TextEditingController _descriptionController;

  String _name = "";
  String _description = "";

  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    if (_translations == null) {
      _translations = Translations.of(context);
    }
    if(_titleController == null) {
      _titleController = TextEditingController(text: _name);
    }

    if(_descriptionController == null){
      _descriptionController = TextEditingController(text: _description);
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          elevation: 0,
          centerTitle: false,
          brightness: Theme.of(context).brightness,
          iconTheme: Theme.of(context).iconTheme,
          title: Text(
            _translations.text("screens.channel.creation.title"),
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
                      hintText: "Channel Name (minimum of 2 characters)",
                    ),
                    onChanged: (text){
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
                    maxLength: 240,
                    maxLengthEnforced: true,
                    onChanged: (text){
                      _description = text;
                    },
                    decoration: InputDecoration(hintText: "Channel Description (minimum of 10 characters)", floatingLabelBehavior: FloatingLabelBehavior.always),
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
                  "Create Channel",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  _createChannel();
                },
              ),
      ),
    );
  }

  void _createChannel() async {
    String title = _name.trim();
    String description =_description.trim();
    String visibility = "PUBLIC";

    if (title.isEmpty || title.length < 2 || description.trim().isEmpty || description.length < 10) {
      print("returning....");
      return;
    }

    setState(() {
      _processing = true;
    });

    Response response = await ChannelResource.createChannel(context, {"name": title, "description": description, "visibility": visibility});

    setState(() {
      _processing = false;
    });

    if (response.statusCode == HttpStatus.conflict) {
      WidgetUtils.showAlertDialog(context, "Duplicate", "You already have a channel named '" + title + "'");
      return;
    }

    if (response.statusCode != HttpStatus.created) {
      WidgetUtils.showAlertDialog(context, _translations.text("screens.common.error.general.title"), _translations.text("screens.common.error.general.message"));
      return;
    }

    locator<NavigationService>().pop(result: true);
  }
}
