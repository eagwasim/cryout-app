import 'dart:convert';
import 'dart:io';

import 'package:cryout_app/http/channel-resource.dart';
import 'package:cryout_app/models/search-channels.dart';
import 'package:cryout_app/utils/extensions.dart';
import 'package:cryout_app/utils/navigation-service.dart';
import 'package:cryout_app/utils/routes.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_text_drawable/flutter_text_drawable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:progress_indicators/progress_indicators.dart';

class ChannelSearchScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChannelSearchScreenState();
  }
}

class _ChannelSearchScreenState extends State {
  TextEditingController _searchController;
  bool _isSearching = false;
  String _nextSearchText = "";
  String _currentText = "";

  List<SearchChannel> channels = [];

  @override
  void initState() {
    super.initState();
    search("");
  }
  @override
  Widget build(BuildContext context) {
    if (_searchController == null) {
      _searchController = TextEditingController(text: _currentText);
    }

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).backgroundColor,
          elevation: 4,
          centerTitle: false,
          brightness: Theme.of(context).brightness,
          iconTheme: Theme.of(context).iconTheme,
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (text) {
                    _currentText = text;
                    search(text);
                  },
                  onChanged: (text) {
                    _currentText = text;
                    search(text);
                  },
                  decoration: InputDecoration(hintText: "Search channels", border: InputBorder.none),
                ),
              ),
              Center(
                child: !_isSearching
                    ? Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              FontAwesomeIcons.eye,
                              color: Colors.brown.withAlpha(50),
                              size: 15,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              FontAwesomeIcons.eye,
                              color: Colors.brown.withAlpha(50),
                              size: 15,
                            ),
                          ),
                        ],
                      )
                    : GlowingProgressIndicator(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Icon(
                                FontAwesomeIcons.eye,
                                color: Colors.brown,
                                size: 15,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Icon(
                                FontAwesomeIcons.eye,
                                color: Colors.brown,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
              )
            ],
          ),
        ),
        body: ListView.builder(
          itemCount: channels.length,
          itemBuilder: (_, int position) {
            final item = channels[position];
            return _getSearchView(item, position);
          },
        ),
      ),
    );
  }

  Widget _getSearchView(SearchChannel channel, int position) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4, bottom: 0, top: 8),
      child: InkWell(
        onTap: () {
          locator<NavigationService>().pushNamed(Routes.CHANNEL_INFORMATION_SCREEN, arguments: channel.id).then((value) {
            if (value != null && value) {
              locator<NavigationService>().pop(result: true);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 4),
                child: TextDrawable(
                  key: Key("${channel.id}-${Theme.of(context).brightness.index}"),
                  text: channel.name,
                  backgroundColor: WidgetUtils.colorFromId(context, channel.id),
                ),
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 0.0, left: 8.0, top: 0, bottom: 4),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(channel.name.titleCapitalize(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              channel.creatorName.capitalize(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Text(
                            channel.city.capitalize() + ", " + channel.country.capitalize(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 10),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Divider(),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void search(String text) async {
    if (_isSearching) {
      _nextSearchText = text;
      return;
    }

    setState(() {
      _nextSearchText = null;
      _isSearching = true;
    });

    Response response = await ChannelResource.searchChannels(context, text);

    setState(() {
      _isSearching = false;
    });

    if (response.statusCode == HttpStatus.ok) {
      channels.clear();

      dynamic data = jsonDecode(response.body)['data'];

      setState(() {
        channels.addAll((data as List<dynamic>).map((e) => SearchChannel.fromJSON(e)).toList());
      });
    }

    if (_nextSearchText != null) {
      search(_nextSearchText);
    }
  }
}
