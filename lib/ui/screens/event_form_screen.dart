import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/event.dart';
import '../../data/models/reminder.dart';
import '../state/app_provider.dart';

class EventFormScreen extends StatefulWidget {
  final AppEvent? eventToEdit; // รับค่ามาถ้าเป็นการแก้ไข
  const EventFormScreen({super.key, this.eventToEdit});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  int _priority = 2;
  
  bool _enableReminder = false;
  int _minutesBefore = 15;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();

    final provider = context.read<AppProvider>();

    if (widget.eventToEdit != null) {
      // [NEW] โหลดข้อมูลเดิมมาใส่ฟอร์ม
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _descController.text = e.description;
      _selectedCategoryId = e.categoryId;
      _selectedDate = DateTime.parse(e.eventDate);
      
      final startParts = e.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      
      final endParts = e.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      
      _priority = e.priority;
      // การดึง Reminder ซับซ้อนเกิน Lab ข้ามไปก่อน ให้ user ตั้งใหม่ถ้าต้องการ
    } else {
      // Default Category
      if (provider.categories.isNotEmpty) {
        _selectedCategoryId = provider.categories.first.id;
      }
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

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกประเภทกิจกรรม')));
      return;
    }

    final newEvent = AppEvent(
      id: widget.eventToEdit?.id, // ถ้าแก้ไขต้องใส่ ID
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      categoryId: _selectedCategoryId!,
      eventDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      startTime: '${_startTime.hour.toString().padLeft(2,'0')}:${_startTime.minute.toString().padLeft(2,'0')}',
      endTime: '${_endTime.hour.toString().padLeft(2,'0')}:${_endTime.minute.toString().padLeft(2,'0')}',
      status: widget.eventToEdit?.status ?? 'pending',
      priority: _priority,
    );

    final provider = context.read<AppProvider>();
    
    if (widget.eventToEdit != null) {
      // [NEW] เรียกใช้ Edit
      await provider.editEvent(newEvent);
    } else {
      // เรียกใช้ Add
      final eventId = await provider.addEvent(newEvent);
      // Save Reminder logic (เฉพาะตอนสร้างใหม่เพื่อความง่าย)
      if (_enableReminder) {
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
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isEdit = widget.eventToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'แก้ไขกิจกรรม' : 'สร้างกิจกรรมใหม่')),
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
             TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'รายละเอียด', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'ประเภทกิจกรรม', border: OutlineInputBorder()),
              items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),

            ListTile(
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              title: Text('วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

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
            
            if (!isEdit) ...[
              const SizedBox(height: 16),
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
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveForm,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึกกิจกรรม', style: const TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}