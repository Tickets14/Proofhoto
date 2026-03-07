/// A hardcoded definition of every possible badge.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.hint,
    this.isGlobal = true,
  });

  /// Unique badge type key (matches Achievement.id).
  final String id;
  final String name;
  final String description;
  final String emoji;

  /// Shown in place of description when the badge is locked.
  final String hint;

  /// True = one badge for the whole app; false = one badge per habit.
  final bool isGlobal;
}

const kBadges = <BadgeDefinition>[
  BadgeDefinition(
    id: 'first_proof',
    name: 'First Step',
    description: 'Completed your first habit with proof.',
    emoji: '🌟',
    hint: 'Complete your very first habit to unlock.',
  ),
  BadgeDefinition(
    id: 'streak_7',
    name: 'On Fire',
    description: '7-day streak on any habit.',
    emoji: '🔥',
    hint: 'Keep a habit streak going for a full week.',
    isGlobal: false,
  ),
  BadgeDefinition(
    id: 'streak_30',
    name: 'Monthly Master',
    description: '30-day streak on any habit.',
    emoji: '👑',
    hint: 'Maintain a 30-day streak on any habit.',
    isGlobal: false,
  ),
  BadgeDefinition(
    id: 'streak_100',
    name: 'Centurion',
    description: '100-day streak on any habit.',
    emoji: '💎',
    hint: 'Reach 100 consecutive days on any habit.',
    isGlobal: false,
  ),
  BadgeDefinition(
    id: 'streak_365',
    name: 'Legendary',
    description: '365-day streak on any habit.',
    emoji: '🏆',
    hint: 'A full year streak — are you legendary enough?',
    isGlobal: false,
  ),
  BadgeDefinition(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Completed a habit before 7 AM.',
    emoji: '🐦',
    hint: 'Complete any habit before 7:00 in the morning.',
  ),
  BadgeDefinition(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Completed a habit after 11 PM.',
    emoji: '🦉',
    hint: 'Complete any habit after 23:00 at night.',
  ),
  BadgeDefinition(
    id: 'perfect_week',
    name: 'Perfect Week',
    description: 'Completed all habits every day for a full week.',
    emoji: '⭐',
    hint: 'Hit 100% on every habit for an entire Mon–Sun.',
  ),
  BadgeDefinition(
    id: 'perfect_month',
    name: 'Perfect Month',
    description: '100% completion for a full calendar month.',
    emoji: '🌕',
    hint: 'Never miss a single scheduled habit for an entire month.',
  ),
  BadgeDefinition(
    id: 'five_habits',
    name: 'Juggler',
    description: 'Tracking 5 or more active habits.',
    emoji: '🤹',
    hint: 'Add 5 or more habits to your list.',
  ),
  BadgeDefinition(
    id: 'photo_50',
    name: 'Snapshot Pro',
    description: 'Took 50 proof photos.',
    emoji: '📸',
    hint: 'Record your 50th proof entry.',
  ),
  BadgeDefinition(
    id: 'photo_500',
    name: 'Visual Diary',
    description: 'Took 500 proof photos.',
    emoji: '📷',
    hint: 'Record your 500th proof entry.',
  ),
];

/// Look up a badge definition by id. Returns null if not found.
BadgeDefinition? badgeById(String id) {
  try {
    return kBadges.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}
