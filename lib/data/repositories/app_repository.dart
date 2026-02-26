import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../models/reminder.dart';

class AppRepository {
  // =========================================
  // CATEGORIES
  // =========================================
  Future<List<EventCategory>> getAllCategories() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((e) => EventCategory.fromMap(e)).toList();
  }

  Future<int> insertCategory(EventCategory category) async {
    final db = await AppDatabase.instance.database;
    final data = category.toMap();
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert('categories', data);
  }

  // [NEW] ฟังก์ชันแก้ไขหมวดหมู่
  Future<int> updateCategory(EventCategory category) async {
    final db = await AppDatabase.instance.database;
    final data = category.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('categories', data, where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================
  // EVENTS
  // =========================================
  Future<int> insertEvent(AppEvent event) async {
    final db = await AppDatabase.instance.database;
    final data = event.toMap();
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert('events', data);
  }

  Future<int> updateEvent(AppEvent event) async {
    final db = await AppDatabase.instance.database;
    final data = event.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('events', data, where: 'id = ?', whereArgs: [event.id]);
  }

  // [NEW] ฟังก์ชันลบกิจกรรม
  Future<int> deleteEvent(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AppEvent>> getAllEvents({String orderBy = 'event_date ASC, start_time ASC'}) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('events', orderBy: orderBy);
    return maps.map((e) => AppEvent.fromMap(e)).toList();
  }

  // =========================================
  // REMINDERS & STATUS LOGIC
  // =========================================
  Future<int> insertReminder(Reminder reminder) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('reminders', reminder.toMap()..remove('id'));
  }

  Future<List<Reminder>> getRemindersForEvent(int eventId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('reminders', where: 'event_id = ?', whereArgs: [eventId]);
    return maps.map((e) => Reminder.fromMap(e)).toList();
  }

  Future<void> updateEventStatus(int eventId, String newStatus) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'events',
      {'status': newStatus, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );

    if (newStatus == 'completed' || newStatus == 'cancelled') {
      await db.update(
        'reminders',
        {'is_enabled': 0},
        where: 'event_id = ? AND is_enabled = 1',
        whereArgs: [eventId],
      );
    }
  }
}