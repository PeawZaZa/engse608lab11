class EventCategory {
  final int? id;
  final String name;
  final String colorHex;
  final String iconKey;

  EventCategory({
    this.id, // id ไม่ควรมี required เพราะตอนสร้าง fallback เราไม่ได้ใส่ id
    required this.name,
    required this.colorHex,
    required this.iconKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_key': iconKey,
      // created_at, updated_at จะจัดการตอน insert/update ใน Database
    };
  }

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      id: map['id'],
      name: map['name'],
      colorHex: map['color_hex'],
      iconKey: map['icon_key'],
    );
  }
}