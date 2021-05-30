import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class databaseHelper {
  static final DATABASE_NAME = "firegasdetection.db";
  static final DATABASE_VERSION = 1;

  static final TABLE_USER = 'table_user';
  static final U_COL_ID = 'id';
  static final U_COL_USER = 'user';

  databaseHelper._privateConstructor();

  static final databaseHelper instance = databaseHelper._privateConstructor();

  static Database _database;

  Future<Database> get database async {
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DATABASE_NAME);
    return await openDatabase(path,
        version: DATABASE_VERSION, onCreate: _onCreate, onUpgrade: onUpgradeDB);
  }

  Future _onCreate(Database db, int version) async {
    print("onCreate");
    await db.execute(
        '''CREATE TABLE IF NOT EXISTS $TABLE_USER ($U_COL_ID INTEGER PRIMARY KEY AUTOINCREMENT, $U_COL_USER TEXT)''');
  }

  Future onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    print("onUpgrade");
    await db.execute(
        '''CREATE TABLE IF NOT EXISTS $TABLE_USER ($U_COL_ID INTEGER PRIMARY KEY AUTOINCREMENT, $U_COL_USER TEXT)''');
  }

  Future<int> insertUserData(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(TABLE_USER, row);
  }

  Future<List<Map<String, dynamic>>> getUserData() async {
    Database db = await instance.database;
    return await db.query(TABLE_USER);
  }

  Future<int> deleteUserData() async {
    Database db = await instance.database;
    return await db.delete(TABLE_USER);
  }

  Future<int> userRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $TABLE_USER'));
  }
}
