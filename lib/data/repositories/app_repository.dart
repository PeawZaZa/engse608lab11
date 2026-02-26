import '../db/app_database.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../models/reminder.dart';

class AppRepository {
  // =========================================
  // CATEGORIES [cite: 533]
  // =========================================
  Future<List<EventCategory>> getAllCategories() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((e) => EventCategory.fromMap(e)).toList();
  }

// =========================================
  // CATEGORIES
  // =========================================
  Future<int> insertCategory(EventCategory category) async {
    final db = await AppDatabase.instance.database;
    final data = category.toMap();
    data.remove('id');
    // เพิ่มเวลาสร้างและอัปเดต
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.insert('categories', data);
  }

  Future<int> deleteCategory(int id) async {
    final db = await AppDatabase.instance.database;
    // ป้องกันการลบประเภทที่มีการใช้งานอยู่ (SQLite จะแจ้ง Error จาก Foreign Key RESTRICT ที่เราตั้งไว้) [cite: 539]
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

// =========================================
  // EVENTS
  // =========================================
  Future<int> insertEvent(AppEvent event) async {
    final db = await AppDatabase.instance.database;
    final data = event.toMap();
    data.remove('id');
    // เพิ่มเวลาสร้างและอัปเดตก่อนบันทึก
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.insert('events', data);
  }

  Future<int> updateEvent(AppEvent event) async {
    final db = await AppDatabase.instance.database;
    final data = event.toMap();
    // อัปเดตแค่เวลา updated_at (created_at ปล่อยไว้ตามเดิม)
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update('events', data, where: 'id = ?', whereArgs: [event.id]);
  }

  Future<int> deleteEvent(int id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ดึงข้อมูลกิจกรรมทั้งหมด พร้อมรองรับการเรียงลำดับ [cite: 579]
  Future<List<AppEvent>> getAllEvents({String orderBy = 'event_date ASC, start_time ASC'}) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('events', orderBy: orderBy);
    return maps.map((e) => AppEvent.fromMap(e)).toList();
  }

  // =========================================
  // REMINDERS & STATUS LOGIC [cite: 560, 562]
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

  // เปลี่ยนสถานะกิจกรรม และตรวจสอบว่าถ้าเป็น Completed/Cancelled ให้ปิดแจ้งเตือน 
  Future<void> updateEventStatus(int eventId, String newStatus) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'events',
      {'status': newStatus, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );

    // ถ้าสถานะคือ เสร็จสิ้น หรือ ยกเลิก ให้ปิดการแจ้งเตือน (is_enabled = 0) [cite: 556, 557, 560]
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