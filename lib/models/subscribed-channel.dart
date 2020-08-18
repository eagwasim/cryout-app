import 'package:cryout_app/utils/database-provider.dart';
import 'package:cryout_app/utils/etc-utils.dart';
import 'package:sqflite/sqflite.dart';

class SubscribedChannel {
  int id;
  String name;
  String description;
  String role;
  String latestPostText;
  String readStatus;
  String creatorName;

  int latestPostId;
  int dateCreated;
  int subscriberCount;

  SubscribedChannel({this.id, this.name, this.description, this.role, this.latestPostText, this.readStatus, this.latestPostId, this.dateCreated, this.subscriberCount, this.creatorName});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "role": role,
      "latestPostText": latestPostText,
      "readStatus": readStatus,
      "latestPostId": latestPostId,
      "dateCreated": dateCreated,
      "subscriberCount": subscriberCount,
    };
  }

  static SubscribedChannel fromJSON(dynamic json) {
    return SubscribedChannel(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        role: json["role"],
        latestPostText: json["latestPostText"],
        readStatus: json["readStatus"],
        latestPostId: json["latestPostId"],
        dateCreated: EtcUtils.dateTimeFrom(json["dateCreated"]),
        subscriberCount: json["subscriberCount"],
    );
  }
}

class SubscribedChannelRepository {
  static Future<List<SubscribedChannel>> all() async {
    final db = await DatabaseProvider.dbp.database;

    List<Map<String, dynamic>> result = await db.rawQuery("select * from subscribed_channels order by dateCreated desc");

    if (result.isEmpty) {
      return [];
    }

    return result.map((e) => SubscribedChannel.fromJSON(e)).toList();
  }

  static Future<SubscribedChannel> getById(int id) async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from subscribed_channels where id = '$id' limit 1");

    if (result.isEmpty) {
      return null;
    }

    return result.map((e) => SubscribedChannel.fromJSON(e)).toList().first;
  }

  static Future<void> save(SubscribedChannel entity) async {
    final db = await DatabaseProvider.dbp.database;

    Map<String, dynamic> data = entity.toJson();
    await db.insert("subscribed_channels", data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> hasUnOpened() async {
    final db = await DatabaseProvider.dbp.database;
    return Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM subscribed_channels where readStatus = 'UNREAD'")) > 0;
  }

  static Future<void> markAllAsOpened() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("update subscribed_channels set readStatus = 'UNREAD' where readStatus = 'READ'");
  }

  static Future<void> delete(SubscribedChannel entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from subscribed_channels where id = '${entity.id}'");
  }

  static Future<void> clear() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from subscribed_channels");
  }
}
