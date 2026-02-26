import 'package:flutter/material.dart';
import '../../data/models/category.dart';
import '../../data/models/event.dart';
import '../../data/models/reminder.dart';
import '../../data/repositories/app_repository.dart';

class AppProvider extends ChangeNotifier {
  final AppRepository repo;
  AppProvider(this.repo);

  bool isLoading = false;
  String? errorMessage;

  // ข้อมูลต้นฉบับ
  List<EventCategory> categories = [];
  List<AppEvent> allEvents = [];
  
  // ข้อมูลที่แสดงใน UI (ผ่านการกรองแล้ว) 
  List<AppEvent> displayEvents = [];

  // ตัวแปรสำหรับ Filter/Search 
  String searchQuery = '';
  int? filterCategoryId;
  String? filterStatus;
  String filterDateRange = 'all'; // all, today, week, month [cite: 576]
  String sortBy = 'closest'; // closest, latest [cite: 579]

  // =========================================
  // INITIALIZE
  // =========================================
  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      categories = await repo.getAllCategories();
      await fetchEvents();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // =========================================
  // EVENTS & FILTERING 
  // =========================================
  Future<void> fetchEvents() async {
    String orderClause = sortBy == 'closest' 
        ? 'event_date ASC, start_time ASC' 
        : 'updated_at DESC';
        
    allEvents = await repo.getAllEvents(orderBy: orderClause);
    applyFilters();
  }

  void applyFilters() {
    displayEvents = allEvents.where((event) {
      // 1. ค้นหาด้วยชื่อ (Search Query) [cite: 575]
      if (searchQuery.isNotEmpty && !event.title.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      // 2. กรองตาม Category [cite: 577]
      if (filterCategoryId != null && event.categoryId != filterCategoryId) {
        return false;
      }
      // 3. กรองตาม Status [cite: 578]
      if (filterStatus != null && event.status != filterStatus) {
        return false;
      }
      
      // 4. กรองตาม วันที่ (Date Filter) [cite: 576]
      if (filterDateRange != 'all') {
        final now = DateTime.now();
        final eventDate = DateTime.parse(event.eventDate);
        
        if (filterDateRange == 'today') {
          if (eventDate.year != now.year || eventDate.month != now.month || eventDate.day != now.day) return false;
        } else if (filterDateRange == 'month') {
          if (eventDate.year != now.year || eventDate.month != now.month) return false;
        }
        // *หมายเหตุ: สัปดาห์นี้ (week) อาจต้องใช้ logic เช็คช่วงวันที่เพิ่ม แต่เบื้องต้นทำ today/month ให้ใช้งานได้ก่อน
      }
      
      return true;
    }).toList();
    
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    applyFilters();
  }

  void setFilters({int? categoryId, String? status, String? dateRange, String? sort}) {
    if (categoryId != null) filterCategoryId = categoryId;
    if (status != null) filterStatus = status;
    if (dateRange != null) filterDateRange = dateRange;
    if (sort != null) {
      sortBy = sort;
      fetchEvents(); // ถ้าเปลี่ยน sort ต้องดึง DB ใหม่เพื่อให้ ORDER BY ทำงาน [cite: 579]
      return; 
    }
    applyFilters();
  }

  void clearFilters() {
    searchQuery = '';
    filterCategoryId = null;
    filterStatus = null;
    filterDateRange = 'all';
    applyFilters();
  }

  // =========================================
  // ACTIONS (CRUD) [cite: 541, 534]
  // =========================================
// --- แก้ไข/เพิ่ม โค้ดส่วนนี้ใน AppProvider ---
  Future<int> addEvent(AppEvent event) async {
    final newId = await repo.insertEvent(event);
    await fetchEvents();
    return newId; // คืนค่า ID เพื่อเอาไปผูกกับ Reminder
  }

  Future<void> addReminder(Reminder reminder) async {
    await repo.insertReminder(reminder);
  }

  Future<void> addCategory(EventCategory category) async {
    await repo.insertCategory(category);
    categories = await repo.getAllCategories();
    notifyListeners();
  }
  
  Future<void> deleteCategory(int id) async {
    try {
      await repo.deleteCategory(id);
      categories = await repo.getAllCategories();
      notifyListeners();
    } catch (e) {
      throw Exception('ไม่สามารถลบได้ อาจมีกิจกรรมที่ใช้ประเภทนี้อยู่');
    }
  }

  Future<void> changeEventStatus(int eventId, String newStatus) async {
    await repo.updateEventStatus(eventId, newStatus);
    await fetchEvents();
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
}