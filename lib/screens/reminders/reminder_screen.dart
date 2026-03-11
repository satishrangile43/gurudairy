import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// 1. Reminder Model
class Reminder {
  final String note;
  final DateTime dateTime;
  final String tone;

  Reminder({required this.note, required this.dateTime, required this.tone});

  Map<String, dynamic> toJson() => {
        'note': note,
        'dateTime': dateTime.toIso8601String(),
        'tone': tone,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        note: json['note'],
        dateTime: DateTime.parse(json['dateTime']),
        tone: json['tone'],
      );
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDateTime;
  String _selectedTone = "Default Tone";
  List<Reminder> _allReminders = [];

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadAllReminders();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- FIX: Aapka naya function yahan sahi tarike se add kar diya hai ---
  Future<void> _scheduleNotification(Reminder reminder, int id) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: 'GuruDiary Reminder',
      body: reminder.note,
      scheduledDate: tz.TZDateTime.from(reminder.dateTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'guru_reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _loadAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersRaw = prefs.getString('all_reminders');
    if (remindersRaw != null) {
      List<dynamic> decoded = jsonDecode(remindersRaw);
      setState(() {
        _allReminders = decoded.map((item) => Reminder.fromJson(item)).toList();
      });
    }
  }

  Future<void> _addNewReminder() async {
    if (_noteController.text.isEmpty || _selectedDateTime == null) {
      _showSnackBar("Kripya saari details bharein");
      return;
    }

    final newReminder = Reminder(
      note: _noteController.text,
      dateTime: _selectedDateTime!,
      tone: _selectedTone,
    );

    // Notification ID generate karna
    int reminderId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Notification schedule karna
    await _scheduleNotification(newReminder, reminderId);

    setState(() {
      _allReminders.add(newReminder);
      _noteController.clear();
      _selectedDateTime = null;
      _selectedTone = "Default Tone";
    });

    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        jsonEncode(_allReminders.map((e) => e.toJson()).toList());
    await prefs.setString('all_reminders', encodedData);

    _showSnackBar("Reminder Set & Saved!");
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (!mounted || date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted || time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Text("Total: ${_allReminders.length}"),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Kya yaad dilana hai?"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: "Math Class Test...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Kab ka reminder?"),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: Colors.orange.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.alarm, color: Colors.orange),
                    title: Text(_selectedDateTime == null
                        ? "Select Date & Time"
                        : DateFormat('dd MMM, hh:mm a')
                            .format(_selectedDateTime!)),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Tone"),
                  DropdownButton<String>(
                    value: _selectedTone,
                    isExpanded: true,
                    items: [
                      "Default Tone",
                      "Bell",
                      "Whistle",
                      "Teacher Special"
                    ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedTone = val!),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      onPressed: _addNewReminder,
                      child: const Text("ADD REMINDER",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(thickness: 2),
          Expanded(
            flex: 1,
            child: _allReminders.isEmpty
                ? const Center(child: Text("No reminders yet"))
                : ListView.builder(
                    itemCount: _allReminders.length,
                    itemBuilder: (context, index) {
                      final item = _allReminders[index];
                      return ListTile(
                        title: Text(item.note),
                        subtitle: Text(DateFormat('dd MMM, hh:mm a')
                            .format(item.dateTime)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () async {
                            setState(() => _allReminders.removeAt(index));
                            final prefs = await SharedPreferences.getInstance();
                            final String encodedData = jsonEncode(
                                _allReminders.map((e) => e.toJson()).toList());
                            await prefs.setString('all_reminders', encodedData);
                            // Note: Real world mein yahan notification cancel bhi karna chahiye notificationId se
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
  }
}
