import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/event.dart';
import '../state/app_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final AppEvent event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // อัปเดตข้อมูล event ปัจจุบันจาก provider (เผื่อมีการเปลี่ยนสถานะ)
    final currentEvent = provider.allEvents.firstWhere(
      (e) => e.id == event.id,
      orElse: () => event,
    );

    final category = provider.categories.firstWhere(
      (c) => c.id == currentEvent.categoryId,
      orElse: () => provider.categories.first,
    );
    Color catColor = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดกิจกรรม')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: catColor, size: 16),
              const SizedBox(width: 8),
              Text(category.name, style: TextStyle(color: catColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(currentEvent.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('วันที่: ${currentEvent.eventDate}'),
              subtitle: Text('เวลา: ${currentEvent.startTime} - ${currentEvent.endTime}'),
            ),
          ),
          
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

  Widget _statusButton(BuildContext context, AppEvent event, String statusValue, String label, Color color) {
    final isActive = event.status == statusValue;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(color: isActive ? color : Colors.black, fontWeight: isActive ? FontWeight.bold : null),
      onSelected: (selected) {
        if (selected) {
          context.read<AppProvider>().changeEventStatus(event.id!, statusValue);
        }
      },
    );
  }
}