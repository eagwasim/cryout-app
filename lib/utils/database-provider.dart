import 'package:cryout_app/models/notification.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider dbp = DatabaseProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await openDB();
    return _database;
  }

  closeDB() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  openDB() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + '/cry_out_v0.db';

    // Delete the database
    //deleteDatabase(path);

    return await openDatabase(
      // Set the path to the database.
      path,
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        db.execute("CREATE TABLE notifications (notificationId TEXT PRIMARY KEY, notificationType TEXT, notificationData TEXT, dateCreated INTEGER, opened INTEGER);");
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

}
