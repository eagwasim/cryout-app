import 'package:cryout_app/models/channel.dart';
import 'package:flutter/widgets.dart';

class ChannelPostsWidget extends StatefulWidget {
  final Channel channel;

  const ChannelPostsWidget({Key key, this.channel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChannelPostsWidgetState(this.channel);
  }
}

class _ChannelPostsWidgetState extends State {
  final Channel _channel;

  _ChannelPostsWidgetState(this._channel);

  String _cursor;
  int page = 0;
  int limit = 100;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Channel Posts"),
    );
  }

  Future<void> initLoad() async {

  }
}
