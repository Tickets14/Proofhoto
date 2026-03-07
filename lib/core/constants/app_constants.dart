abstract final class AppConstants {
  // Hive box names
  static const habitsBox = 'habits';
  static const proofEntriesBox = 'proofEntries';
  static const settingsBox = 'settings';
  static const settingsKey = 'userSettings';
  static const categoriesBox = 'categories';

  // Image settings
  static const imageMaxWidth = 1080;
  static const imageQuality = 80;
  static const proofDir = 'proof';

  // Video settings
  static const videoMaxSeconds = 15;

  // Habit limits
  static const habitNameMaxLength = 40;
  static const noteMaxLength = 200;

  // Streak
  static const maxFreezesbanked = 3;
  static const freezesPerStreakMilestone = 7; // earn 1 freeze every 7-day milestone

  // Animations
  static const shortDuration = Duration(milliseconds: 200);
  static const mediumDuration = Duration(milliseconds: 350);
  static const longDuration = Duration(milliseconds: 500);

  // Notification channel
  static const notificationChannelId = 'proof_reminders';
  static const notificationChannelName = 'Habit Reminders';
  static const notificationChannelDesc = 'Daily reminders to complete your habits';

  // Days of week labels (index 0 = Monday, index 6 = Sunday)
  static const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const dayFullLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Default emojis for quick pick
  static const quickEmojis = [
    '🏃', '💪', '🧘', '📚', '✍️', '🎨', '🎵', '💻',
    '🥗', '💧', '😴', '🧹', '🌿', '🐕', '🚴', '🏊',
    '🎯', '📝', '🌅', '🏋️', '🧠', '💊', '🫁', '❤️',
    '🌙', '☕', '🍎', '🚶', '🧪', '📖', '🎤', '🎸',
  ];

  // Border radius
  static const cardRadius = 16.0;
  static const buttonRadius = 12.0;
  static const imageRadius = 12.0;
  static const chipRadius = 8.0;

  // Spacing
  static const screenPadding = 20.0;
  static const cardPadding = 16.0;
  static const itemSpacing = 12.0;
}
