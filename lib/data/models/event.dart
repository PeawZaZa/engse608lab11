class AppEvent {
  final int? id;
  final String title;
  final String description;
  final int categoryId;
  final String eventDate; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime;   // HH:mm
  final String status;    // pending, in_progress, completed, cancelled
  final int priority;     // 1-3

  AppEvent({
    this.id, required this.title, required this.description, 
    required this.categoryId, required this.eventDate, 
    required this.startTime, required this.endTime, 
    required this.status, required this.priority
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'priority': priority,
    };
  }

  factory AppEvent.fromMap(Map<String, dynamic> map) {
    return AppEvent(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      categoryId: map['category_id'],
      eventDate: map['event_date'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      status: map['status'],
      priority: map['priority'],
    );
  }
}