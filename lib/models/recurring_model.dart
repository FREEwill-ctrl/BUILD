enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

extension RecurrenceTypeExtension on RecurrenceType {
  String get name {
    switch (this) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }
}

class RecurrenceRule {
  final int? id;
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek; // 1-7 (Monday-Sunday)
  final int? dayOfMonth; // 1-31
  final DateTime? endDate;
  final int? maxOccurrences;
  final DateTime createdAt;

  RecurrenceRule({
    this.id,
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.maxOccurrences,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'interval': interval,
      'daysOfWeek': daysOfWeek?.join(','),
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.millisecondsSinceEpoch,
      'maxOccurrences': maxOccurrences,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    return RecurrenceRule(
      id: map['id'],
      type: RecurrenceType.values[map['type']],
      interval: map['interval'] ?? 1,
      daysOfWeek: map['daysOfWeek'] != null
          ? map['daysOfWeek'].split(',').map<int>((e) => int.parse(e)).toList()
          : null,
      dayOfMonth: map['dayOfMonth'],
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      maxOccurrences: map['maxOccurrences'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  RecurrenceRule copyWith({
    int? id,
    RecurrenceType? type,
    int? interval,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    DateTime? endDate,
    int? maxOccurrences,
    DateTime? createdAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime? getNextOccurrence(DateTime from) {
    switch (type) {
      case RecurrenceType.daily:
        return from.add(Duration(days: interval));
      case RecurrenceType.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          // Find next day of week
          final currentWeekday = from.weekday;
          final sortedDays = [...daysOfWeek!]..sort();
          
          for (final day in sortedDays) {
            if (day > currentWeekday) {
              return from.add(Duration(days: day - currentWeekday));
            }
          }
          // Next week
          return from.add(Duration(days: 7 - currentWeekday + sortedDays.first));
        }
        return from.add(Duration(days: 7 * interval));
      case RecurrenceType.monthly:
        if (dayOfMonth != null) {
          final nextMonth = DateTime(from.year, from.month + interval, dayOfMonth!);
          return nextMonth.isAfter(from) ? nextMonth : DateTime(from.year, from.month + interval + 1, dayOfMonth!);
        }
        return DateTime(from.year, from.month + interval, from.day);
      case RecurrenceType.yearly:
        return DateTime(from.year + interval, from.month, from.day);
      case RecurrenceType.custom:
        return from.add(Duration(days: interval));
    }
  }

  String get description {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceType.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final days = daysOfWeek!.map((d) => _getDayName(d)).join(', ');
          return 'Weekly on $days';
        }
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceType.monthly:
        if (dayOfMonth != null) {
          return 'Monthly on day $dayOfMonth';
        }
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      case RecurrenceType.custom:
        return 'Every $interval days';
    }
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}