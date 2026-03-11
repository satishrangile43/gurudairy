import 'package:flutter/material.dart';
import 'screens/attendance/class_list_screen.dart';
import 'screens/books/subject_list_screen.dart';
import 'screens/timetable/timetable_screen.dart';
import 'screens/notes/notedown_screen.dart';
// Naye Imports: In files ko create karna padega
import 'screens/reminders/reminder_screen.dart';
import 'screens/holidays/holiday_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "GuruDiary",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Teacher!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Manage your classes and notes offline."),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                      context, "Attendance", Icons.how_to_reg, Colors.blue),
                  _buildMenuCard(
                      context, "Books", Icons.menu_book, Colors.orange),
                  _buildMenuCard(
                      context, "Timetable", Icons.grid_on, Colors.green),
                  _buildMenuCard(context, "Reminder",
                      Icons.notification_important, Colors.red),
                  _buildMenuCard(
                      context, "NoteDown", Icons.edit_note, Colors.purple),
                  _buildMenuCard(
                      context, "Holidays", Icons.beach_access, Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // --- NAVIGATION LOGIC FIXED ---
        if (title == "Attendance") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ClassListScreen()));
        } else if (title == "Books") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubjectListScreen()));
        } else if (title == "Timetable") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const TimetableScreen()));
        } else if (title == "NoteDown") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const NoteDownScreen()));
        } else if (title == "Reminder") {
          // AB YE WORK KAREGA
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ReminderScreen()));
        } else if (title == "Holidays") {
          // AB YE BHI WORK KAREGA
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HolidayScreen()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(50),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
