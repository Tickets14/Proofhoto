import 'package:flutter/material.dart';

/// Named route paths.
abstract final class AppRoutes {
  static const home = '/';
  static const createHabit = '/habits/create';
  static const editHabit = '/habits/edit';
  static const captureProof = '/proof/capture';
  static const proofDetail = '/proof/detail';

  /// Global navigator key — used by NotificationUtils to push routes
  /// directly from the notification callback (foreground + background taps).
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Set by NotificationUtils when a notification is tapped and the navigator
  /// is not yet available (cold-start). _AppShell reads and clears this.
  static String? pendingNotificationHabitId;
}
