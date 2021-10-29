import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models/user.dart';

class DatabaseHelper{
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDB();

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'mydatabase.db');
    return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async{
    await db.execute('''
      CREATE TABLE User (
        firstName TEXT,
        lastName TEXT,
        username TEXT,
        password TEXT
      )
    ''');
    await db.execute(
        'INSERT INTO User (firstName, lastName, username, password) VALUES ("Admin", "Admin", "admin", "Admin")'
    );
    print('Database Initialized.');
  }
    Future<List<User>> getUsers() async{
      Database db = await instance.database;
      var users = await db.query('User', orderBy: 'lastName');
      List<User> userList = users.isNotEmpty
      ? users.map((c) => User.fromMap(c)).toList() : [];
      print(userList);
      return userList;
    }

    Future<bool> authenticateLogin(String username, String password) async{
      Database db = await instance.database;
      var userRow = await db.rawQuery('SELECT * FROM User WHERE username=? and password=?', [username, password]
      );
      userRow.isNotEmpty ? print('Login success for user ' + username) : print('Login failed for user ' + username);
      Future<bool> rval = userRow.isNotEmpty ? Future<bool>.value(true) : Future<bool>.value(false);
      return rval;
    }

    Future<bool> addUser(String firstName, String lastName, String username, String password) async {
      Database db = await instance.database;
      var userRow = await db.rawQuery('SELECT * FROM User WHERE username=?', [username]);
      if (userRow.isEmpty){
        await db.rawInsert('INSERT INTO User VALUES (?, ?, ?, ?)', [firstName, lastName, username, password]);
        print('Inserted user ' + username);
        return Future<bool>.value(true);
      }
      else{
        print('Could not insert ' + username + '. Username already exists.');
        return Future<bool>.value(false);
      }
    }

    void removeUser(String username) async {
      Database db = await instance.database;
      await db.rawQuery('DELETE from User where username=?', [username]);
      print('Removed user ' + username);
    }

    void clearDb() async{
      Database db = await instance.database;
      await db.execute('DELETE from User where username!="admin"');
      print('Cleared database.');
    }

    void deleteDb() async{
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, "mydatabase.db");
      await deleteDatabase(path);
      print('Deleted database.');
    }

  Future<User> getUserByUsername(String username) async {
    Database db = await instance.database;
    List users = await db.query("User", where: "username = ?", whereArgs: [username], limit: 1);
    return User.fromMap(users[0]);
  }

}