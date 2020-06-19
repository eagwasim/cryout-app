import 'package:cryout_app/utils/database-provider.dart';
import 'package:sqflite/sqflite.dart';

class InAppNotification {
  String notificationId;
  String notificationType;
  String notificationData;

  int dateCreated;
  int opened = 0;

  InAppNotification({this.notificationId, this.notificationType, this.notificationData, this.dateCreated, this.opened});

  static InAppNotification fromJSON(dynamic json) {
    return InAppNotification(
        notificationId: json["notificationId"], notificationType: json["notificationType"], notificationData: json["notificationData"], dateCreated: json["dateCreated"], opened: json["opened"]);
  }

  Map<String, dynamic> toJson() {
    return {"notificationId": notificationId, "notificationType": notificationType, "notificationData": notificationData, "dateCreated": dateCreated, "opened": opened};
  }
}

class NotificationRepository {
  static Future<List<InAppNotification>> getAll() async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from notifications order by dateCreated desc");

    if (result.isEmpty) {
      return [];
    }

    return result.map((e) => InAppNotification.fromJSON(e)).toList();
  }

  static Future<InAppNotification> getById(String id) async {
    final db = await DatabaseProvider.dbp.database;
    List<Map<String, dynamic>> result = await db.rawQuery("select * from notifications where notificationId = '$id'");

    if (result.isEmpty) {
      return null;
    }

    return result.map((e) => InAppNotification.fromJSON(e)).toList().first;
  }

  static Future<void> save(InAppNotification notification) async {
    final db = await DatabaseProvider.dbp.database;
    await db.insert("notifications", notification.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> hasUnReadNotifications() async {
    final db = await DatabaseProvider.dbp.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM notifications where opened = 0')) > 0;
  }

  static Future<void> clearUnreadNotificationCount() async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery('update notifications set opened = 1 where opened = 0');
  }

  static Future<void> deleteNotification(InAppNotification inAppNotification) async {
    final db = await DatabaseProvider.dbp.database;
    await db.rawQuery("delete from notifications where notificationId = '${inAppNotification.notificationId}'");
  }
}
