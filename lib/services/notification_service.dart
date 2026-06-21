// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';
import '../repositories/todo_repository.dart';
import '../repositories/note_repository.dart';

/// Notification ID ranges supaya tidak saling bertabrakan:
/// - Todo reminders: id = hashTodoId(todoId) * 10 + offset(0,1,2)
///   offset 0 = H-2jam, 1 = H-1jam, 2 = tepat waktu
/// - Daily reminder: id tetap = 999999
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderId = 999999;
  static const String _prefKeyDailyEnabled = 'daily_reminder_enabled';
  static const String _prefKeyDailyHour = 'daily_reminder_hour';
  static const String _prefKeyDailyMinute = 'daily_reminder_minute';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Jakarta (WIB). Kalau target user beda timezone, ganti sesuai kebutuhan.
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  /// Minta izin notifikasi (Android 13+) dan exact alarm (Android 12+).
  /// Panggil ini saat app pertama kali jalan atau dari halaman Settings.
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final notifGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      final exactAlarmGranted =
          await androidPlugin.requestExactAlarmsPermission() ?? false;
      return notifGranted && exactAlarmGranted;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  // ===== TODO REMINDERS (3x: -2jam, -1jam, tepat waktu) =====

  /// Hash sederhana dan stabil dari String id menjadi int positif < 100000,
  /// supaya base ID tidak overflow saat dikali 10 dan ditambah offset.
  int _todoBaseId(String todoId) {
    final hash = todoId.hashCode & 0x7FFFFFFF;
    return (hash % 100000) * 10;
  }

  List<int> _todoNotificationIds(String todoId) {
    final base = _todoBaseId(todoId);
    return [base, base + 1, base + 2];
  }

  /// Jadwalkan 3 notifikasi untuk satu todo berdasarkan dueDate-nya.
  /// Notifikasi yang waktunya sudah lewat (di masa lalu) otomatis dilewati.
  Future<void> scheduleTodoReminders(Todo todo) async {
    // Selalu cancel dulu yang lama, supaya kalau dueDate diedit,
    // tidak ada notifikasi basi yang nyangkut.
    await cancelTodoReminders(todo.id);

    if (todo.dueDate == null || todo.isCompleted) return;

    final due = todo.dueDate!;
    final ids = _todoNotificationIds(todo.id);

    final schedule = <_ReminderSpec>[
      _ReminderSpec(
        id: ids[0],
        time: due.subtract(const Duration(hours: 2)),
        title: '⏰ ${todo.title}',
        body: 'Jatuh tempo 2 jam lagi',
      ),
      _ReminderSpec(
        id: ids[1],
        time: due.subtract(const Duration(hours: 1)),
        title: '⏰ ${todo.title}',
        body: 'Jatuh tempo 1 jam lagi',
      ),
      _ReminderSpec(
        id: ids[2],
        time: due,
        title: '🔔 ${todo.title}',
        body: 'Waktunya sekarang!',
      ),
    ];

    final now = DateTime.now();
    for (final spec in schedule) {
      if (spec.time.isBefore(now)) continue; // skip waktu yang sudah lewat
      await _plugin.zonedSchedule(
        spec.id,
        spec.title,
        spec.body,
        tz.TZDateTime.from(spec.time, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_reminders',
            'Pengingat Todo',
            channelDescription: 'Notifikasi pengingat jatuh tempo todo',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTodoReminders(String todoId) async {
    for (final id in _todoNotificationIds(todoId)) {
      await _plugin.cancel(id);
    }
  }

  /// Reschedule ulang semua reminder todo aktif. Dipanggil saat boot device
  /// (lewat receiver native) atau saat app dibuka kembali sebagai fallback.
  Future<void> rescheduleAllTodoReminders() async {
    final repository = TodoRepository();
    final todos = await repository.getAll();
    for (final todo in todos) {
      if (!todo.isCompleted && todo.dueDate != null) {
        await scheduleTodoReminders(todo);
      }
    }
  }

  // ===== DAILY REMINDER (todo + note harian, berulang) =====

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyDailyEnabled) ?? false;
  }

  Future<TimeOfDayPref> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_prefKeyDailyHour) ?? 8;
    final minute = prefs.getInt(_prefKeyDailyMinute) ?? 0;
    return TimeOfDayPref(hour: hour, minute: minute);
  }

  /// Aktifkan/matikan + atur jam daily reminder. Dipanggil dari Settings.
  Future<void> setDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDailyEnabled, enabled);
    await prefs.setInt(_prefKeyDailyHour, hour);
    await prefs.setInt(_prefKeyDailyMinute, minute);

    if (enabled) {
      await _scheduleDailyReminder(hour, minute);
    } else {
      await _plugin.cancel(dailyReminderId);
    }
  }

  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    await _plugin.cancel(dailyReminderId);

    // Hitung ringkasan isi notifikasi saat ini (akan tetap fix sampai
    // reschedule berikutnya, karena flutter_local_notifications tidak bisa
    // generate isi secara dinamis saat notifikasi benar-benar muncul).
    final body = await _buildDailySummaryText();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      dailyReminderId,
      '📋 Ringkasan Hari Ini',
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Pengingat Harian',
          channelDescription: 'Ringkasan todo dan note harian',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ulang tiap hari
    );
  }

  Future<String> _buildDailySummaryText() async {
    try {
      final todoRepo = TodoRepository();
      final noteRepo = NoteRepository();
      final todos = await todoRepo.getAll();
      final activeCount = todos.where((t) => !t.isCompleted).length;
      final today = DateTime.now();
      final notesToday = await noteRepo.getByDate(today);

      return 'Kamu punya $activeCount todo aktif dan ${notesToday.length} note hari ini. Yuk cek!';
    } catch (_) {
      return 'Yuk cek todo dan jurnal kamu hari ini!';
    }
  }

  /// Reschedule daily reminder dengan isi summary terbaru. Sebaiknya
  /// dipanggil tiap kali app dibuka (initState halaman utama) supaya teks
  /// ringkasannya selalu fresh untuk notifikasi besok.
  Future<void> refreshDailyReminderIfEnabled() async {
    final enabled = await isDailyReminderEnabled();
    if (!enabled) return;
    final time = await getDailyReminderTime();
    await _scheduleDailyReminder(time.hour, time.minute);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

class _ReminderSpec {
  final int id;
  final DateTime time;
  final String title;
  final String body;

  _ReminderSpec({
    required this.id,
    required this.time,
    required this.title,
    required this.body,
  });
}

class TimeOfDayPref {
  final int hour;
  final int minute;
  TimeOfDayPref({required this.hour, required this.minute});
}
