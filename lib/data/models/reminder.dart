class Reminder {
  final int? id;
  final int eventId;
  final int minutesBefore;
  final String remindAt; // datetime ISO string
  final int isEnabled;   // 0 หรือ 1

  Reminder({
    this.id, required this.eventId, required this.minutesBefore, 
    required this.remindAt, required this.isEnabled
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'minutes_before': minutesBefore,
      'remind_at': remindAt,
      'is_enabled': isEnabled,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      eventId: map['event_id'],
      minutesBefore: map['minutes_before'],
      remindAt: map['remind_at'],
      isEnabled: map['is_enabled'],
    );
  }
}