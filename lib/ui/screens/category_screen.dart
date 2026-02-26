import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/category.dart';
import '../state/app_provider.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  void _showCategoryDialog(BuildContext context, {EventCategory? categoryToEdit}) {
    final isEdit = categoryToEdit != null;
    final nameCtrl = TextEditingController(text: isEdit ? categoryToEdit.name : '');
    final provider = context.read<AppProvider>();
    
    String selectedColor = isEdit ? categoryToEdit.colorHex : '#FF5722';
    final colors = ['#FF5722', '#2196F3', '#4CAF50', '#9C27B0', '#FFC107'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'แก้ไขประเภท' : 'เพิ่มประเภทใหม่'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ชื่อประเภท'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: colors.map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: CircleAvatar(
                        backgroundColor: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        child: selectedColor == c ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    if (isEdit) {
                      // UPDATE
                      final updatedCat = EventCategory(
                        id: categoryToEdit.id,
                        name: nameCtrl.text.trim(),
                        colorHex: selectedColor,
                        iconKey: categoryToEdit.iconKey,
                      );
                      provider.editCategory(updatedCat);
                    } else {
                      // INSERT
                      provider.addCategory(EventCategory(
                        name: nameCtrl.text.trim(),
                        colorHex: selectedColor,
                        iconKey: 'bookmark',
                      ));
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('บันทึก'),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการประเภทกิจกรรม')),
      body: ListView.builder(
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final cat = provider.categories[index];
          final color = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));
          return ListTile(
            leading: Icon(Icons.circle, color: color),
            title: Text(cat.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ปุ่มแก้ไข
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showCategoryDialog(context, categoryToEdit: cat),
                ),
                // ปุ่มลบ
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await provider.deleteCategory(cat.id!);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}