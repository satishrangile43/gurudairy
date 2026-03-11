import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'attendance_sheet_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  // Ab list khali rakhenge, data Hive se aayega
  List<String> classes = [];
  final TextEditingController _classController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClasses(); // Screen khulte hi data load karo
  }

  // Hive se classes load karne ka function
  Future<void> _loadClasses() async {
    var box = await Hive.openBox('attendance_store');
    List? savedClasses = box.get('my_classes_list');
    if (savedClasses != null) {
      setState(() {
        classes = List<String>.from(savedClasses);
      });
    }
  }

  // Hive mein list save karne ka function
  Future<void> _saveClassesToHive() async {
    var box = await Hive.openBox('attendance_store');
    await box.put('my_classes_list', classes);
  }

  // --- ADD FUNCTION ---
  void _addClass() async {
    if (_classController.text.isNotEmpty) {
      setState(() {
        classes.add(_classController.text);
      });
      await _saveClassesToHive(); // Save to Hive
      _classController.clear();
      if (mounted) Navigator.pop(context);
    }
  }

  // --- DELETE FUNCTION ---
  Future<void> _deleteClass(int index) async {
    String className = classes[index];
    var box = await Hive.openBox('attendance_store');

    await box.delete('students_$className');
    await box.delete('data_$className');

    setState(() {
      classes.removeAt(index);
    });
    await _saveClassesToHive(); // Update list in Hive
  }

  // --- RENAME FUNCTION ---
  Future<void> _renameClass(int index, String newName) async {
    if (newName.isEmpty) return;

    String oldName = classes[index];
    var box = await Hive.openBox('attendance_store');

    var students = box.get('students_$oldName');
    var data = box.get('data_$oldName');

    if (students != null) await box.put('students_$newName', students);
    if (data != null) await box.put('data_$newName', data);

    await box.delete('students_$oldName');
    await box.delete('data_$oldName');

    setState(() {
      classes[index] = newName;
    });
    await _saveClassesToHive(); // Update list in Hive
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Classes"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: classes.isEmpty
          ? const Center(child: Text("No classes added. Click + to add."))
          : ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.groups)),
                    title: Text(classes[index],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(index);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(index);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text("Rename")
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Delete", style: TextStyle(color: Colors.red))
                          ]),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AttendanceSheetScreen(className: classes[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog() {
    _classController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Class Name"),
        content: TextField(
          controller: _classController,
          decoration: const InputDecoration(hintText: "Enter Name (e.g. MCA)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(onPressed: _addClass, child: const Text("Add")),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    TextEditingController editController =
        TextEditingController(text: classes[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Class"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _renameClass(index, editController.text);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Class"),
        content: Text("Are you sure you want to delete '${classes[index]}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _deleteClass(index);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
