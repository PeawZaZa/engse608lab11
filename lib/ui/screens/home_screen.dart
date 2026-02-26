import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_provider.dart';
import 'event_form_screen.dart';
import 'event_detail_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event & Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: EventSearchDelegate(provider)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'sort_closest') provider.setFilters(sort: 'closest');
              if (value == 'sort_latest') provider.setFilters(sort: 'latest');
              if (value == 'clear') provider.clearFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sort_closest', child: Text('เรียงเวลาใกล้สุด')),
              const PopupMenuItem(value: 'sort_latest', child: Text('เรียงอัปเดตล่าสุด')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear', child: Text('ล้างตัวกรอง')),
            ],
          ),
        ],
      ),
      // --- เพิ่มเมนู Drawer ตรงนี้ ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text('เมนูหลัก', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('จัดการประเภทกิจกรรม'),
              onTap: () {
                Navigator.pop(context); // ปิด Drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
              },
            ),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.displayEvents.isEmpty
              ? const Center(child: Text('ไม่มีกิจกรรม'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.displayEvents.length,
                  itemBuilder: (context, index) {
                    final event = provider.displayEvents[index];
                    final category = provider.categories.firstWhere(
                      (c) => c.id == event.categoryId,
                      orElse: () => provider.categories.first,
                    );
                    Color catColor = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: InkWell(
                        // --- เพิ่ม Navigator ไปหน้ารายละเอียด ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 100,
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${event.eventDate} | ${event.startTime} - ${event.endTime}'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildStatusChip(event.status),
                                        const SizedBox(width: 8),
                                        Text(category.name, style: TextStyle(color: catColor, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  // (ฟังก์ชัน _buildStatusChip และ EventSearchDelegate ใช้ตัวเดิมจาก Part 3 ได้เลยครับ)
  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'in_progress': color = Colors.blue; text = 'กำลังทำ'; break;
      case 'completed': color = Colors.green; text = 'เสร็จสิ้น'; break;
      case 'cancelled': color = Colors.red; text = 'ยกเลิก'; break;
      default: color = Colors.grey; text = 'ยังไม่เริ่ม';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class EventSearchDelegate extends SearchDelegate {
  final AppProvider provider;
  EventSearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () { provider.setSearchQuery(''); close(context, null); },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    provider.setSearchQuery(query);
    WidgetsBinding.instance.addPostFrameCallback((_) => close(context, null));
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox();
}