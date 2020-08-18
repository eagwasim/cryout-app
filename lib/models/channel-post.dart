import 'package:cryout_app/utils/etc-utils.dart';

class ChannelPost {
  int id;
  String title;
  String message;
  String creatorName;
  String creatorId;
  String creatorImage;
  int dateCreated;

  ChannelPost({this.id, this.title, this.message, this.creatorName, this.creatorId, this.creatorImage, this.dateCreated});

  static ChannelPost fromJSON(dynamic json) {
    return ChannelPost(
      id: json["id"],
      title: json["title"],
      message: json["message"],
      creatorName: json["creatorName"],
      creatorId: json["creatorId"],
      creatorImage: json["creatorImage"],
      dateCreated: EtcUtils.dateTimeFrom(json["dateCreated"]),
    );
  }
}
