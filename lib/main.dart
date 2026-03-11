import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'dashboard_screen.dart';
import 'models/book_model.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TIMEZONE INITIALIZATION
  tz.initializeTimeZones();

  // NOTIFICATION INITIALIZATION
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      // Notification click logic
    },
  );

  // 🔔 NOTIFICATION CHANNEL WITH SOUND
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'guru_channel',
    'Guru Diary Notifications',
    description: 'Notification for reminders',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('bell'),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // HIVE DATABASE INITIALIZATION
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(BookModelAdapter());
  }

  await Future.wait([
    Hive.openBox('attendance_store'),
    Hive.openBox<BookModel>('books'),
    Hive.openBox('timetable_store'),
    Hive.openBox('notes_box'),
    Hive.openBox('holidays_box'),
  ]);

  runApp(const GuruDiary());
}

class GuruDiary extends StatelessWidget {
  const GuruDiary({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuruDiary',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
