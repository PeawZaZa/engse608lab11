import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// นำเข้า Repository และ Provider
import 'data/repositories/app_repository.dart';
import 'ui/state/app_provider.dart';

// นำเข้าหน้าจอหลัก
import 'ui/screens/home_screen.dart';

void main() {
  // บังคับให้ Flutter เริ่มต้นการทำงานของวิดเจ็ตต่างๆ ให้พร้อมก่อน (จำเป็นสำหรับการเรียกใช้ SQLite ทันทีตอนเปิดแอป)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EventReminderApp());
}

class EventReminderApp extends StatelessWidget {
  const EventReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Provider สำหรับจัดการ Database (AppRepository)
        Provider<AppRepository>(
          create: (_) => AppRepository(),
        ),
        // 2. Provider สำหรับจัดการ State ของ UI (AppProvider)
        ChangeNotifierProvider<AppProvider>(
          create: (context) => AppProvider(
            context.read<AppRepository>(),
          )..loadInitialData(), // โหลดข้อมูลหมวดหมู่และกิจกรรมจาก DB ทันทีที่แอปเปิด
        ),
      ],
      child: MaterialApp(
        title: 'Event & Reminder',
        debugShowCheckedModeBanner: false, // ปิดแถบ Debug สีแดงมุมขวาบน
        theme: ThemeData(
          // กำหนดธีมสีหลักของแอป
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true, // ใช้งานดีไซน์แบบ Material 3
        ),
        // ตั้งค่าหน้าแรกของแอปให้ชี้ไปที่ HomeScreen
        home: const HomeScreen(),
      ),
    );
  }
}