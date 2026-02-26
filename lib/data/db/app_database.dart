import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  static const dbName = 'event_reminder.db';
  static const dbVersion = 1;
  Database? _db;

  AppDatabase._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, dbName);
    
    return openDatabase(
      dbPath,
      version: dbVersion,
      onConfigure: (db) async {
        // บังคับเปิดใช้งาน Foreign Key Constraints เสมอ
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        // 1. ตาราง Categories
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            icon_key TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // 2. ตาราง Events
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            category_id INTEGER NOT NULL,
            event_date TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            status TEXT NOT NULL,
            priority INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
          )
        ''');

        // 3. ตาราง Reminders
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER NOT NULL,
            minutes_before INTEGER NOT NULL,
            remind_at TEXT NOT NULL,
            is_enabled INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
          )
        ''');

        // ข้อมูลตั้งต้น (Mock Category) ไว้ใช้เทส
        await db.rawInsert("INSERT INTO categories (name, color_hex, icon_key, created_at, updated_at) VALUES ('ประชุม', '#FF5722', 'meeting', datetime('now'), datetime('now'))");
        await db.rawInsert("INSERT INTO categories (name, color_hex, icon_key, created_at, updated_at) VALUES ('งานเอกสาร', '#2196F3', 'document', datetime('now'), datetime('now'))");
      },
    );
  }
}