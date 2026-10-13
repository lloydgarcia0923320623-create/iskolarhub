import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../screens/models/scholarship.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleDeadlineReminders(
    List<Scholarship> scholarships,
  ) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    final now = tz.TZDateTime.now(tz.local);

    for (final scholarship in scholarships) {
      if (scholarship.isArchived) continue;
      final deadline = tz.TZDateTime.from(scholarship.deadline, tz.local);
      final reminder = deadline.subtract(const Duration(days: 7));
      final id = _notificationId(scholarship.id);
      if (!reminder.isAfter(now)) {
        await _plugin.cancel(id: id);
        continue;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: 'Scholarship deadline reminder',
        body: '${scholarship.name} closes in 7 days.',
        scheduledDate: reminder,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'scholarship_deadlines',
            'Scholarship deadlines',
            channelDescription: 'Reminders for saved scholarship deadlines',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> notifyScholarshipUpdates(int updatedCount) async {
    if (updatedCount <= 0) return;
    await initialize();
    await _plugin.show(
      id: 0x49534B,
      title: 'Scholarships updated',
      body: updatedCount == 1
          ? 'One scholarship record has new information.'
          : '$updatedCount scholarship records have new information.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'scholarship_updates',
          'Scholarship information updates',
          channelDescription:
              'Notifications when cached scholarship information changes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancelAllDeadlineReminders() async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
  }

  int _notificationId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
