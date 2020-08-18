import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class StaticPageScreen extends StatefulWidget {
  final WebPageModel webPageModel;

  const StaticPageScreen({Key key, this.webPageModel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StaticPageScreenState(webPageModel);
  }
}

// ignore: prefer_collection_literals
final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {

      }),
].toSet();

class _StaticPageScreenState extends State {
  final WebPageModel webPageModel;

  _StaticPageScreenState(this.webPageModel);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: WebviewScaffold(
          url: webPageModel.url,
          javascriptChannels: jsChannels,
          mediaPlaybackRequiresUserGesture: false,
          appBar: AppBar(
            brightness: Theme.of(context).brightness,
            elevation: 1,
            backgroundColor: Theme.of(context).backgroundColor,
            iconTheme: Theme.of(context).iconTheme,
            title: Text(webPageModel.title, style: TextStyle(color: Theme.of(context).iconTheme.color)),
          ),
          withZoom: true,
          withLocalStorage: true,
          hidden: true,
          initialChild: Container(
            color: Theme.of(context).backgroundColor,
            child: const Center(
              child: Text('Loading...'),
            ),
          )),
    );
  }
}

class WebPageModel {
  final String title;
  final String url;

  const WebPageModel(this.title, this.url);
}
