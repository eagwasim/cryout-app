import 'package:cryout_app/utils/database-provider.dart';
import 'package:cryout_app/utils/etc-utils.dart';
import 'package:sqflite/sqflite.dart';

class ReceivedSafeWalk {
  int id;
  String safeWalkId;
  String userId;
  String destination;
  String userFirstName;
  String userLastName;
  String userPhoto;
  String userPhoneNumber;
  String status;
  int dateCreated;
  int opened;

  ReceivedSafeWalk({this.id, this.userId, this.destination, this.dateCreated, this.userFirstName, this.userLastName, this.userPhoto, this.safeWalkId, this.opened, this.userPhoneNumber, this.status});

  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "userId": userId,
      "destination": destination,
      "dateCreated": dateCreated,
      "userFirstName": userFirstName,
      "userLastName": userLastName,
      "userPhoto": userPhoto,
      "safeWalkId": safeWalkId,
      "opened": opened,
      "userPhoneNumber": userPhoneNumber,
      "status": status
    };
  }

  static ReceivedSafeWalk fromJSON(dynamic json) {
    return ReceivedSafeWalk(
      id: json["id"],
      userId: json["userId"],
      destination: json["destination"],
      dateCreated: EtcUtils.dateTimeFrom(json["dateCreated"]),
      userPhoto: json["userPhoto"],
      safeWalkId: json["safeWalkId"],
      userLastName: json["userLastName"],
      userFirstName: json["userFirstName"],
      opened: json["opened"] ?? 0,
      status: json["status"] ?? null,
      userPhoneNumber: json["userPhoneNumber"] ?? null,
    );
  }
}

class ReceivedSafeWalkRepository {
  static Future<List<ReceivedSafeWalk>> all() async {
    final db = await DatabaseProvider.dbp.database;

    List<Map<String, dynamic>> result = await db.rawQuery("select * from received_safe_walks order by dateCreated desc");

    if (result.isEmpty) {
      return [];
    }

    return result.map((e) => ReceivedSafeWalk.fromJSON(e)).toList();
  }

  static Future<ReceivedSafeWalk> getById(int id) async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from received_safe_walks where id = '$id' limit 1");

    if (result.isEmpty) {
      return null;
    }

    return result.map((e) => ReceivedSafeWalk.fromJSON(e)).toList().first;
  }

  static Future<void> save(ReceivedSafeWalk entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.insert("received_safe_walks", entity.toJSON(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> hasUnOpened() async {
    final db = await DatabaseProvider.dbp.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM received_safe_walks where opened = 0')) > 0;
  }

  static Future<void> markAllAsOpened() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery('update received_safe_walks set opened = 1 where opened = 0');
  }

  static Future<void> delete(ReceivedSafeWalk entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from received_safe_walks where id = '${entity.id}'");
  }

  static Future<void> clear() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from received_safe_walks");
  }
}
