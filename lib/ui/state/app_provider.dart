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

  List<EventCategory> categories = [];
  List<AppEvent> allEvents = [];
  List<AppEvent> displayEvents = [];

  // Filter Variables
  String searchQuery = '';
  int? filterCategoryId;
  String? filterStatus;
  String filterDateRange = 'all'; // all, today, month
  String sortBy = 'closest';

  // INITIALIZE
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

  // EVENTS CRUD
  Future<void> fetchEvents() async {
    String orderClause = sortBy == 'closest' 
        ? 'event_date ASC, start_time ASC' 
        : 'updated_at DESC';
    allEvents = await repo.getAllEvents(orderBy: orderClause);
    applyFilters();
  }

  Future<int> addEvent(AppEvent event) async {
    final newId = await repo.insertEvent(event);
    await fetchEvents();
    return newId;
  }

  // [NEW] แก้ไขกิจกรรม
  Future<void> editEvent(AppEvent event) async {
    await repo.updateEvent(event);
    await fetchEvents();
  }

  // [NEW] ลบกิจกรรม
  Future<void> deleteEvent(int id) async {
    await repo.deleteEvent(id);
    await fetchEvents();
  }

  Future<void> changeEventStatus(int eventId, String newStatus) async {
    await repo.updateEventStatus(eventId, newStatus);
    await fetchEvents();
  }

  Future<void> addReminder(Reminder reminder) async {
    await repo.insertReminder(reminder);
  }

  // CATEGORY CRUD
  Future<void> addCategory(EventCategory category) async {
    await repo.insertCategory(category);
    categories = await repo.getAllCategories();
    notifyListeners();
  }

  // [NEW] แก้ไขหมวดหมู่
  Future<void> editCategory(EventCategory category) async {
    await repo.updateCategory(category);
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


  // FILTERS
  void applyFilters() {
    displayEvents = allEvents.where((event) {
      // 1. Search
      if (searchQuery.isNotEmpty && !event.title.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      // 2. Category
      if (filterCategoryId != null && event.categoryId != filterCategoryId) {
        return false;
      }
      // 3. Status
      if (filterStatus != null && event.status != filterStatus) {
        return false;
      }
      // 4. Date
      if (filterDateRange != 'all') {
        final now = DateTime.now();
        final eventDate = DateTime.parse(event.eventDate);
        if (filterDateRange == 'today') {
          if (eventDate.year != now.year || eventDate.month != now.month || eventDate.day != now.day) return false;
        } else if (filterDateRange == 'month') {
          if (eventDate.year != now.year || eventDate.month != now.month) return false;
        }
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
    if (categoryId != null) filterCategoryId = (categoryId == -1) ? null : categoryId;
    if (status != null) filterStatus = (status == 'all') ? null : status;
    if (dateRange != null) filterDateRange = dateRange;
    if (sort != null) {
      sortBy = sort;
      fetchEvents();
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

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
}