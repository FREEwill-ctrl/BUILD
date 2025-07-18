enum AchievementType {
  firstTask,
  streak,
  productivity,
  consistency,
  special,
}

class Achievement {
  final int? id;
  final String name;
  final String description;
  final String iconPath;
  final DateTime? unlockedAt;
  final int points;
  final AchievementType type;
  final Map<String, dynamic>? criteria; // JSON criteria for unlocking
  final bool isUnlocked;

  Achievement({
    this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    this.unlockedAt,
    required this.points,
    required this.type,
    this.criteria,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
      'points': points,
      'type': type.index,
      'criteria': criteria != null ? criteria.toString() : null,
      'isUnlocked': isUnlocked ? 1 : 0,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      iconPath: map['iconPath'],
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'])
          : null,
      points: map['points'],
      type: AchievementType.values[map['type']],
      criteria: map['criteria'] != null ? {} : null, // Parse JSON if needed
      isUnlocked: map['isUnlocked'] == 1,
    );
  }

  Achievement copyWith({
    int? id,
    String? name,
    String? description,
    String? iconPath,
    DateTime? unlockedAt,
    int? points,
    AchievementType? type,
    Map<String, dynamic>? criteria,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      points: points ?? this.points,
      type: type ?? this.type,
      criteria: criteria ?? this.criteria,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

class UserProfile {
  final int totalPoints;
  final int level;
  final List<int> achievementIds;
  final Map<String, int> statistics;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final DateTime createdAt;

  UserProfile({
    this.totalPoints = 0,
    this.level = 1,
    this.achievementIds = const [],
    this.statistics = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'level': level,
      'achievementIds': achievementIds.join(','),
      'statistics': statistics.entries.map((e) => '${e.key}:${e.value}').join(','),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final statsString = map['statistics'] as String? ?? '';
    final stats = <String, int>{};
    if (statsString.isNotEmpty) {
      for (final pair in statsString.split(',')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          stats[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
    }

    return UserProfile(
      totalPoints: map['totalPoints'] ?? 0,
      level: map['level'] ?? 1,
      achievementIds: map['achievementIds'] != null && map['achievementIds'].isNotEmpty
          ? map['achievementIds'].split(',').map<int>((e) => int.parse(e)).toList()
          : [],
      statistics: stats,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: DateTime.fromMillisecondsSinceEpoch(map['lastActiveDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  UserProfile copyWith({
    int? totalPoints,
    int? level,
    List<int>? achievementIds,
    Map<String, int>? statistics,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    DateTime? createdAt,
  }) {
    return UserProfile(
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      achievementIds: achievementIds ?? this.achievementIds,
      statistics: statistics ?? this.statistics,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get pointsToNextLevel => (level * 100) - (totalPoints % (level * 100));
  double get levelProgress => (totalPoints % (level * 100)) / (level * 100);
  int get pointsForCurrentLevel => level * 100;
}

// Default achievements
class DefaultAchievements {
  static List<Achievement> get defaultList => [
    Achievement(
      name: 'First Steps',
      description: 'Complete your first task',
      iconPath: 'assets/icons/first_task.png',
      points: 10,
      type: AchievementType.firstTask,
      criteria: {'completedTasks': 1},
    ),
    Achievement(
      name: 'Getting Started',
      description: 'Complete 10 tasks',
      iconPath: 'assets/icons/ten_tasks.png',
      points: 50,
      type: AchievementType.productivity,
      criteria: {'completedTasks': 10},
    ),
    Achievement(
      name: 'Productive',
      description: 'Complete 50 tasks',
      iconPath: 'assets/icons/fifty_tasks.png',
      points: 200,
      type: AchievementType.productivity,
      criteria: {'completedTasks': 50},
    ),
    Achievement(
      name: 'Task Master',
      description: 'Complete 100 tasks',
      iconPath: 'assets/icons/hundred_tasks.png',
      points: 500,
      type: AchievementType.productivity,
      criteria: {'completedTasks': 100},
    ),
    Achievement(
      name: 'Streak Starter',
      description: 'Maintain a 3-day streak',
      iconPath: 'assets/icons/streak_3.png',
      points: 30,
      type: AchievementType.streak,
      criteria: {'streak': 3},
    ),
    Achievement(
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      iconPath: 'assets/icons/streak_7.png',
      points: 100,
      type: AchievementType.streak,
      criteria: {'streak': 7},
    ),
    Achievement(
      name: 'Consistency King',
      description: 'Maintain a 30-day streak',
      iconPath: 'assets/icons/streak_30.png',
      points: 1000,
      type: AchievementType.streak,
      criteria: {'streak': 30},
    ),
    Achievement(
      name: 'Time Master',
      description: 'Track 10 hours of focused work',
      iconPath: 'assets/icons/time_tracker.png',
      points: 150,
      type: AchievementType.productivity,
      criteria: {'trackedMinutes': 600},
    ),
    Achievement(
      name: 'Pomodoro Pro',
      description: 'Complete 25 Pomodoro sessions',
      iconPath: 'assets/icons/pomodoro_pro.png',
      points: 250,
      type: AchievementType.consistency,
      criteria: {'pomodoroSessions': 25},
    ),
    Achievement(
      name: 'Early Bird',
      description: 'Complete a task before 8 AM',
      iconPath: 'assets/icons/early_bird.png',
      points: 25,
      type: AchievementType.special,
      criteria: {'earlyMorningTask': 1},
    ),
  ];
}