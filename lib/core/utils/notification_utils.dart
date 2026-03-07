import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../router/app_router.dart';

abstract final class NotificationUtils {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    AppConstants.notificationChannelId,
    AppConstants.notificationChannelName,
    channelDescription: AppConstants.notificationChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  /// Call once at app startup after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Handle cold-start tap (app launched via notification).
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      AppRoutes.pendingNotificationHabitId = payload;
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final habitId = response.payload;
    if (habitId == null || habitId.isEmpty) return;

    final nav = AppRoutes.navigatorKey.currentState;
    if (nav != null) {
      // App is running (foreground or background) — navigate immediately.
      nav.pushNamed(AppRoutes.captureProof, arguments: habitId);
    } else {
      // Cold start — shell will pick this up in didChangeDependencies.
      AppRoutes.pendingNotificationHabitId = habitId;
    }
  }

  /// Requests notification permissions on iOS/Android 13+.
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Schedules weekly recurring notifications for a habit.
  ///
  /// [habitId] — used as payload and to derive notification IDs.
  /// [habitName] — shown in notification body.
  /// [reminderDays] — list of 1=Mon … 7=Sun.
  /// [reminderTime] — "HH:mm" string.
  static Future<void> scheduleHabitReminders({
    required String habitId,
    required String habitName,
    required List<int> reminderDays,
    required String reminderTime,
  }) async {
    // Cancel existing notifications for this habit first
    await cancelHabitReminders(habitId);

    final parts = reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    for (final day in reminderDays) {
      final notifId = _notificationId(habitId, day);
      final scheduledDate = _nextWeeklyDate(day, hour, minute);

      try {
        await _plugin.zonedSchedule(
          notifId,
          'Time to $habitName!',
          'Snap your proof 📸',
          scheduledDate,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: habitId,
        );
      } catch (e) {
        debugPrint('NotificationUtils: Failed to schedule for day $day: $e');
      }
    }
  }

  /// Cancels all notifications for a habit.
  static Future<void> cancelHabitReminders(String habitId) async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(_notificationId(habitId, day));
    }
  }

  /// Derives a stable notification ID from habitId + day.
  static int _notificationId(String habitId, int day) =>
      (habitId.hashCode.abs() % 10000) * 10 + day;

  /// Returns the next occurrence of [weekday] (1=Mon…7=Sun) at [hour]:[minute].
  static tz.TZDateTime _nextWeeklyDate(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Advance to the target weekday
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
