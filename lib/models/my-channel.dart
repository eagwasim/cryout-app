import 'package:cryout_app/utils/database-provider.dart';
import 'package:cryout_app/utils/etc-utils.dart';
import 'package:sqflite/sqflite.dart';

class MyChannel {
  int id;
  String name;
  String description;
  int dateCreated;
  int subscriberCount;

  MyChannel({this.id, this.name, this.description, this.dateCreated, this.subscriberCount});

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "description": description, "dateCreated": dateCreated, "subscriberCount": subscriberCount};
  }

  static MyChannel fromJSON(dynamic json) {
    print(json);
    return MyChannel(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      dateCreated: EtcUtils.dateTimeFrom(json["dateCreated"]),
      subscriberCount: json["subscriberCount"],
    );
  }
}

class MyChannelRepository {
  static Future<List<MyChannel>> all() async {
    final db = await DatabaseProvider.dbp.database;

    List<Map<String, dynamic>> result = await db.rawQuery("select * from my_channels order by dateCreated desc");

    if (result.isEmpty) {
      return [];
    }

    return result.map((e) => MyChannel.fromJSON(e)).toList();
  }

  static Future<MyChannel> getById(int id) async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from my_channels where id = '$id' limit 1");

    if (result.isEmpty) {
      return null;
    }

    return result.map((e) => MyChannel.fromJSON(e)).toList().first;
  }

  static Future<void> save(MyChannel entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.insert("my_channels", entity.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> delete(MyChannel entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from my_channels where id = '${entity.id}'");
  }

  static Future<void> clear() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from my_channels");
  }
}
