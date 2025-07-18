class TimeEntry {
  final int? id;
  final int todoId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String? description;
  final DateTime createdAt;

  TimeEntry({
    this.id,
    required this.todoId,
    required this.startTime,
    this.endTime,
    this.duration,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todoId': todoId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'],
      todoId: map['todoId'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'])
          : null,
      description: map['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  TimeEntry copyWith({
    int? id,
    int? todoId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? description,
    DateTime? createdAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isRunning => endTime == null;

  Duration get actualDuration {
    if (duration != null) return duration!;
    if (endTime != null) return endTime!.difference(startTime);
    return DateTime.now().difference(startTime);
  }

  String get formattedDuration {
    final dur = actualDuration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    final seconds = dur.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}