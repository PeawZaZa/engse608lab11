import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/event.dart';
import '../state/app_provider.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final AppEvent event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // ตรวจสอบว่ากิจกรรมนี้ยังอยู่ในระบบหรือไม่ (ป้องกัน Error กรณีถูกลบไปแล้ว)
    final eventExists = provider.allEvents.any((e) => e.id == event.id);
    if (!eventExists) {
       return const Scaffold(body: Center(child: Text("กิจกรรมนี้ถูกลบแล้ว")));
    }

    // ดึงข้อมูลล่าสุด (เผื่อมีการแก้ไข)
    final currentEvent = provider.allEvents.firstWhere((e) => e.id == event.id);
    
    // ดึงข้อมูล Category มาแสดงสี
    final category = provider.categories.firstWhere(
      (c) => c.id == currentEvent.categoryId,
      orElse: () => provider.categories.isNotEmpty 
          ? provider.categories.first 
          : throw Exception("No categories available"),
    );
    
    Color catColor;
    try {
      catColor = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      catColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดกิจกรรม'),
        actions: [
          // ปุ่มแก้ไข
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(
                 builder: (_) => EventFormScreen(eventToEdit: currentEvent)
               ));
            },
          ),
          // --- [ปุ่มลบกิจกรรม] ---
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              // 1. แสดง Popup ยืนยันการลบ
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ยืนยันการลบ'),
                  content: const Text('คุณต้องการลบกิจกรรมนี้ใช่หรือไม่?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false), 
                      child: const Text('ยกเลิก')
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: const Text('ลบ')
                    ),
                  ],
                ),
              );

              // 2. ถ้ากด "ลบ" ให้สั่ง Provider ลบข้อมูลและปิดหน้านี้
              if (confirm == true && context.mounted) {
                await provider.deleteEvent(currentEvent.id!);
                if (context.mounted) Navigator.pop(context); // กลับไปหน้า Home
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ส่วนหัวแสดงประเภท
          Row(
            children: [
              Icon(Icons.circle, color: catColor, size: 16),
              const SizedBox(width: 8),
              Text(category.name, style: TextStyle(color: catColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          
          // ชื่อกิจกรรม
          Text(
            currentEvent.title, 
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          
          // การ์ดแสดงวันเวลา
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('วันที่: ${currentEvent.eventDate}'),
              subtitle: Text('เวลา: ${currentEvent.startTime} - ${currentEvent.endTime}'),
            ),
          ),
          
          // รายละเอียด (ถ้ามี)
          if (currentEvent.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('รายละเอียด:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(currentEvent.description),
          ],
          
          const SizedBox(height: 24),
          const Text('สถานะกิจกรรม:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // ปุ่มเปลี่ยนสถานะ
          Wrap(
            spacing: 8,
            children: [
              _statusButton(context, currentEvent, 'pending', 'ยังไม่เริ่ม', Colors.grey),
              _statusButton(context, currentEvent, 'in_progress', 'กำลังทำ', Colors.blue),
              _statusButton(context, currentEvent, 'completed', 'เสร็จสิ้น', Colors.green),
              _statusButton(context, currentEvent, 'cancelled', 'ยกเลิก', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  // Widget สร้างปุ่มสถานะ
  Widget _statusButton(BuildContext context, AppEvent event, String statusValue, String label, Color color) {
    final isActive = event.status == statusValue;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isActive ? color : Colors.black, 
        fontWeight: isActive ? FontWeight.bold : null
      ),
      onSelected: (selected) {
        if (selected) {
          context.read<AppProvider>().changeEventStatus(event.id!, statusValue);
        }
      },
    );
  }
}