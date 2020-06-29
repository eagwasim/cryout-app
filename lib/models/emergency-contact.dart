import 'package:cryout_app/utils/database-provider.dart';
import 'package:sqflite/sqflite.dart';

class EmergencyContact {
  String fullName;
  String phoneNumber;
  int id;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EmergencyContact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  EmergencyContact({this.fullName, this.phoneNumber, this.id});

  static EmergencyContact fromJSON(dynamic json) {
    return EmergencyContact(fullName: json["fullName"], phoneNumber: json["phoneNumber"], id: json["id"]);
  }

  dynamic toJSON() {
    return {"fullName": fullName, "phoneNumber": phoneNumber, "id": id};
  }
}

class EmergencyContactRepository {
  static Future<List<EmergencyContact>> all() async {
    final db = await DatabaseProvider.dbp.database;

    List<Map<String, dynamic>> result = await db.rawQuery("select * from emergency_contacts order by id desc");

    if (result.isEmpty) {
      return [];
    }

    return result.map((e) => EmergencyContact.fromJSON(e)).toList();
  }

  static Future<EmergencyContact> getById(int id) async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from emergency_contacts where id = '$id' limit 1");

    if (result.isEmpty) {
      return null;
    }

    return result.map((e) => EmergencyContact.fromJSON(e)).toList().first;
  }

  static Future<void> save(EmergencyContact entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.insert("emergency_contacts", entity.toJSON(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> delete(EmergencyContact entity) async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from emergency_contacts where id = '${entity.id}'");
  }

  static Future<void> clear() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from emergency_contacts");
  }
}
