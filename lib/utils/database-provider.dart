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
    String path = databasesPath + '/cry_out.db';

    // Delete the database
    //deleteDatabase(path);

    return await openDatabase(
      // Set the path to the database.
      path,
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        db.execute(
            "CREATE TABLE received_distress_signals (id INTEGER PRIMARY KEY, age TEXT, detail TEXT, dateCreated INTEGER, opened INTEGER, distressId TEXT, firstName TEXT, lastName TEXT, gender TEXT, phone TEXT, photo TEXT, userId TEXT, distance TEXT, location TEXT, status TEXT);");
        db.execute(
            "CREATE TABLE received_safe_walks (id INTEGER PRIMARY KEY, safeWalkId TEXT, userId TEXT, destination TEXT, userFirstName TEXT, userLastName TEXT, userPhoto TEXT, dateCreated INTEGER, opened INTEGER, userPhoneNumber TEXT, status TEXT);");
        db.execute("CREATE TABLE emergency_contacts (id INTEGER PRIMARY KEY, fullName TEXT, phoneNumber TEXT);");
        db.execute("CREATE TABLE my_channels (id INTEGER PRIMARY KEY, name TEXT, description TEXT, dateCreated INTEGER, subscriberCount INTEGER)");
        db.execute(
            "CREATE TABLE subscribed_channels (id INTEGER PRIMARY KEY, name TEXT, description TEXT, dateCreated INTEGER, role TEXT, latestPostText TEXT, latestPostId INTEGER, subscriberCount INTEGER, readStatus TEXT)");
      },

      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute("ALTER TABLE received_safe_walks ADD userPhoneNumber TEXT;");
          db.execute("ALTER TABLE received_safe_walks ADD status TEXT;");
          db.execute("ALTER TABLE received_distress_signals ADD status TEXT;");
        }

        if (oldVersion < 3) {
          db.execute("CREATE TABLE my_channels (id INTEGER PRIMARY KEY, name TEXT, description TEXT, dateCreated INTEGER, subscriberCount INTEGER)");
          db.execute(
              "CREATE TABLE subscribed_channels (id INTEGER PRIMARY KEY, name TEXT, description TEXT, dateCreated INTEGER, role TEXT, latestPostText TEXT, latestPostId INTEGER, subscriberCount INTEGER, readStatus TEXT)");
        }
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 3,
    );
  }
}
