import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/channel.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/pub-sub.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cryout_app/utils/extensions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';

class ChannelAboutWidget extends StatefulWidget {
  final Channel channel;

  const ChannelAboutWidget({Key key, this.channel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelAboutWidgetState(this.channel);
  }
}

class _ChannelAboutWidgetState extends State {
  final Channel _channel;
  bool _deleting = false;

  _ChannelAboutWidgetState(this._channel);

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Text(
          "Description:",
          style: Theme.of(context).textTheme.caption,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Text(_channel.description),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8),
        child: Divider(),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Text(
          "Creator:",
          style: Theme.of(context).textTheme.caption,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Row(
          children: [
            Text(_channel.creatorName),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8),
        child: Divider(),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Text(
          "Location:",
          style: Theme.of(context).textTheme.caption,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Text(_channel.city.capitalize() + ", " + _channel.country),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8),
        child: Divider(),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
        child: Row(
          children: [
            Expanded(
              child: Text("${_channel.subscriberCount} ${_channel.subscriberCount > 1 ? 'subscribers' : 'subscriber'}"),
            ),
            _channel.role == "ADMIN"
                ? _deleting
                    ? Container(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ))
                    : FlatButton.icon(
                        onPressed: () {
                          _deleteConfirmation();
                        },
                        icon: Icon(
                          Icons.delete,
                          size: 14,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.only(left: 8.0, right: 8, top: 0),
                        label: Text(
                          " Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                : SizedBox.shrink(),
          ],
        ),
      )
    ]);
  }

  void _deleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 16, right: 16),
          titlePadding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: new Text("Confirmation"),
          content: new Text(
            "Are you sure you want to delete '${_channel.name}' ?? This can not be undone. All subscriptions would be removed!",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            new FlatButton(
              child: new Text(
                "Yes, Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteChannel();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteChannel() async {
    setState(() {
      _deleting = true;
    });

    Response response = await ChannelResource.deleteChannel(context, _channel.id);

    if (response.statusCode == 200) {
      EventManager.notify(Events.CHANNEL_DELETED, data: _channel.id);
    } else {
      try {
        setState(() {
          _deleting = false;
        });
      } catch (e) {}
    }
  }
}
