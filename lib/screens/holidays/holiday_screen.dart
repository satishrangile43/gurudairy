import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class Holiday {
  String title;
  DateTime date;
  Holiday({required this.title, required this.date});
}

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  List<Holiday> holidays = [];

  late Box holidayBox;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  void _loadHolidays() {
    holidayBox = Hive.box('holidays_box');

    List stored = holidayBox.get('holidays', defaultValue: []);

    holidays = stored.map((e) {
      return Holiday(
        title: e['title'],
        date: DateTime.parse(e['date']),
      );
    }).toList();

    setState(() {});
  }

  void _saveHolidays() {
    List data = holidays.map((h) {
      return {
        'title': h.title,
        'date': h.date.toIso8601String(),
      };
    }).toList();

    holidayBox.put('holidays', data);
  }

  void _addHoliday() async {
    TextEditingController reasonController = TextEditingController();

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Chhutti ka Kaaran"),
          content: TextField(
            controller: reasonController,
            decoration:
                const InputDecoration(hintText: "Jaise: Diwali, Sunday..."),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  setState(() {
                    holidays.add(
                      Holiday(
                        title: reasonController.text,
                        date: selectedDate,
                      ),
                    );
                  });

                  _saveHolidays();

                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      );
    }
  }

  void _deleteHoliday(int index) {
    setState(() {
      holidays.removeAt(index);
    });

    _saveHolidays();
  }

  @override
  Widget build(BuildContext context) {
    holidays.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Holidays List"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: holidays.isEmpty
          ? const Center(child: Text("Abhi koi chhutti nahi hai!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: holidays.length,
              itemBuilder: (context, index) {
                final h = holidays[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.beach_access, color: Colors.teal),
                    ),
                    title: Text(
                      h.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(DateFormat('dd MMMM yyyy').format(h.date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteHoliday(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHoliday,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
