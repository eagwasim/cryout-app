import 'package:cryout_app/utils/database-provider.dart';
import 'package:cryout_app/utils/etc-utils.dart';
import 'package:sqflite/sqflite.dart';

class ReceivedDistressSignal {
  int id;
  String age;
  String detail;
  String distressId;
  String firstName;
  String lastName;
  String gender;
  String phone;
  String photo;
  String userId;
  String distance;
  String location;

  int dateCreated;
  int opened;

  ReceivedDistressSignal({
    this.id,
    this.age,
    this.detail,
    this.dateCreated,
    this.distressId,
    this.firstName,
    this.lastName,
    this.gender,
    this.phone,
    this.photo,
    this.userId,
    this.distance,
    this.location,
    this.opened,
  });

  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "age": age,
      "detail": detail,
      "dateCreated": dateCreated,
      "distressId": distressId,
      "firstName": firstName,
      "lastName": lastName,
      "gender": gender,
      "phone": phone,
      "photo": photo,
      "userId": userId,
      "distance": distance,
      "location": location,
      "opened": opened,
    };
  }

  static ReceivedDistressSignal fromJSON(dynamic json) {
    return ReceivedDistressSignal(
      id: json["id"],
      age: json["age"],
      detail: json["detail"],
      dateCreated: EtcUtils.dateTimeFrom(json["dateCreated"]),
      distressId: json["distressId"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      gender: json["gender"],
      phone: json["phone"],
      photo: json["photo"],
      userId: json["userId"],
      distance: json["distance"],
      location: json["location"],
      opened: json["opened"] ?? 0,
    );
  }
}

class ReceivedDistressSignalRepository {
  static Future<List<ReceivedDistressSignal>> all() async {
    final db = await DatabaseProvider.dbp.database;

    List<Map<String, dynamic>> result = await db.rawQuery("select * from received_distress_signals order by dateCreated desc");

    if (result.isEmpty) {
      return [];
    }

    return result.map((e) => ReceivedDistressSignal.fromJSON(e)).toList();
  }

  static Future<ReceivedDistressSignal> getById(int id) async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from received_distress_signals where id = '$id' limit 1");

    if (result.isEmpty) {
      return null;
    }

    return result.map((e) => ReceivedDistressSignal.fromJSON(e)).toList().first;
  }

  static Future<void> save(ReceivedDistressSignal entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.insert("received_distress_signals", entity.toJSON(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> hasUnOpened() async {
    final db = await DatabaseProvider.dbp.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM received_distress_signals where opened = 0')) > 0;
  }

  static Future<void> markAllAsOpened() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery('update received_distress_signals set opened = 1 where opened = 0');
  }

  static Future<void> delete(ReceivedDistressSignal entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from received_distress_signals where id = '${entity.id}'");
  }

  static Future<void> clear() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from received_distress_signals");
  }
}
