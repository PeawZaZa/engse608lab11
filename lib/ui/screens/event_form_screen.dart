import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/event.dart';
import '../../data/models/reminder.dart';
import '../state/app_provider.dart';

class EventFormScreen extends StatefulWidget {
  final AppEvent? eventToEdit;
  const EventFormScreen({super.key, this.eventToEdit});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  int _priority = 2; // 1=Low, 2=Normal, 3=High
  
  bool _enableReminder = false;
  int _minutesBefore = 15;

  @override
  void initState() {
    super.initState();
    // ถ้ามี Category ในระบบ ให้ default ตัวแรก
    final provider = context.read<AppProvider>();
    if (provider.categories.isNotEmpty) {
      _selectedCategoryId = provider.categories.first.id;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  // --- แทนที่ฟังก์ชัน _saveForm เดิมด้วยโค้ดนี้ ---
  void _saveForm() async { // เปลี่ยนเป็น async
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อผิดพลาด: เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกประเภทกิจกรรม')),
      );
      return;
    }

    final newEvent = AppEvent(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      categoryId: _selectedCategoryId!,
      eventDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      startTime: '${_startTime.hour.toString().padLeft(2,'0')}:${_startTime.minute.toString().padLeft(2,'0')}',
      endTime: '${_endTime.hour.toString().padLeft(2,'0')}:${_endTime.minute.toString().padLeft(2,'0')}',
      status: 'pending',
      priority: _priority,
    );

    final provider = context.read<AppProvider>();
    
    // 1. เซฟ Event และรับ ID กลับมา
    final eventId = await provider.addEvent(newEvent);

    // 2. ถ้าเปิดแจ้งเตือน ให้เซฟ Reminder ลง DB ด้วย
    if (_enableReminder) {
      // คำนวณเวลา remind_at (เวลาเริ่ม - X นาที)
      final startDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 
        _startTime.hour, _startTime.minute
      );
      final remindDateTime = startDateTime.subtract(Duration(minutes: _minutesBefore));

      final reminder = Reminder(
        eventId: eventId,
        minutesBefore: _minutesBefore,
        remindAt: remindDateTime.toIso8601String(),
        isEnabled: 1,
      );
      await provider.addReminder(reminder);
    }

    if (context.mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('สร้างกิจกรรมใหม่')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ชื่อกิจกรรม *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อกิจกรรม' : null,
            ),
            const SizedBox(height: 16),
            
            // Dropdown ประเภทกิจกรรม
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'ประเภทกิจกรรม', border: OutlineInputBorder()),
              items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),

            // เลือกวันที่
            ListTile(
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              title: Text('วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // เลือกเวลา เริ่ม - สิ้นสุด
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    title: Text('เริ่ม: ${_startTime.format(context)}'),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    title: Text('สิ้นสุด: ${_endTime.format(context)}'),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ตั้งค่าการแจ้งเตือน (Reminder) [cite: 586]
            Card(
              elevation: 0,
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('ตั้งการแจ้งเตือน'),
                      value: _enableReminder,
                      onChanged: (val) => setState(() => _enableReminder = val),
                    ),
                    if (_enableReminder)
                      DropdownButtonFormField<int>(
                        value: _minutesBefore,
                        decoration: const InputDecoration(labelText: 'แจ้งเตือนก่อนเริ่ม (นาที)'),
                        items: [5, 10, 15, 30, 60].map((m) => DropdownMenuItem(value: m, child: Text('$m นาที'))).toList(),
                        onChanged: (val) => setState(() => _minutesBefore = val!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            FilledButton(
              onPressed: _saveForm,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('บันทึกกิจกรรม', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}