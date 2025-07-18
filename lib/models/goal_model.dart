enum GoalType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

extension GoalTypeExtension on GoalType {
  String get name {
    switch (this) {
      case GoalType.daily:
        return 'Daily';
      case GoalType.weekly:
        return 'Weekly';
      case GoalType.monthly:
        return 'Monthly';
      case GoalType.yearly:
        return 'Yearly';
      case GoalType.custom:
        return 'Custom';
    }
  }
}

class Goal {
  final int? id;
  final String title;
  final String description;
  final DateTime targetDate;
  final int targetValue;
  final int currentValue;
  final GoalType type;
  final String? unit; // e.g., "tasks", "hours", "points"
  final DateTime createdAt;
  final bool isCompleted;

  Goal({
    this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.targetValue,
    this.currentValue = 0,
    required this.type,
    this.unit,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'type': type.index,
      'unit': unit,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate']),
      targetValue: map['targetValue'],
      currentValue: map['currentValue'] ?? 0,
      type: GoalType.values[map['type']],
      unit: map['unit'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? targetDate,
    int? targetValue,
    int? currentValue,
    GoalType? type,
    String? unit,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progress => currentValue / targetValue;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;
  String get displayUnit => unit ?? 'items';
}

class HabitTracker {
  final int? id;
  final String name;
  final String description;
  final List<DateTime> completedDates;
  final int targetFrequency; // per week
  final DateTime createdAt;
  final bool isActive;

  HabitTracker({
    this.id,
    required this.name,
    required this.description,
    required this.completedDates,
    this.targetFrequency = 7,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'completedDates': completedDates.map((d) => d.millisecondsSinceEpoch).join(','),
      'targetFrequency': targetFrequency,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory HabitTracker.fromMap(Map<String, dynamic> map) {
    return HabitTracker(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      completedDates: map['completedDates'] != null && map['completedDates'].isNotEmpty
          ? map['completedDates'].split(',').map<DateTime>((e) => DateTime.fromMillisecondsSinceEpoch(int.parse(e))).toList()
          : [],
      targetFrequency: map['targetFrequency'] ?? 7,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  HabitTracker copyWith({
    int? id,
    String? name,
    String? description,
    List<DateTime>? completedDates,
    int? targetFrequency,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return HabitTracker(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      completedDates: completedDates ?? this.completedDates,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = [...completedDates]..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final daysDifference = now.difference(date).inDays;
      
      if (daysDifference == i) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  int get longestStreak {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = [...completedDates]..sort();
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final daysDifference = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      
      if (daysDifference == 1) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }

  bool isCompletedToday() {
    final today = DateTime.now();
    return completedDates.any((date) => 
        date.year == today.year && 
        date.month == today.month && 
        date.day == today.day);
  }

  int get thisWeekCompletions {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return completedDates.where((date) => 
        date.isAfter(startOfWeek) && date.isBefore(endOfWeek.add(const Duration(days: 1)))).length;
  }

  double get weeklyProgress => thisWeekCompletions / targetFrequency;
}