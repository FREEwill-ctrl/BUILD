class Todo {
  final int? id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final Priority priority;
  final bool isCompleted;
  final int? categoryId;
  final List<int> tagIds;
  final int? recurrenceRuleId;
  final int? parentRecurringId;
  final String? richDescription;
  final DateTime? completedAt;
  final int estimatedDuration; // in minutes
  final int? actualDuration; // in minutes
  final List<String> tags; // Added tags property

  Todo({
    this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    required this.priority,
    this.isCompleted = false,
    this.categoryId,
    this.tagIds = const [],
    this.recurrenceRuleId,
    this.parentRecurringId,
    this.richDescription,
    this.completedAt,
    this.estimatedDuration = 0,
    this.actualDuration,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'categoryId': categoryId,
      'tagIds': tagIds.join(','),
      'recurrenceRuleId': recurrenceRuleId,
      'parentRecurringId': parentRecurringId,
      'richDescription': richDescription,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'tags': tags.join(','),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      priority: Priority.values[map['priority']],
      isCompleted: map['isCompleted'] == 1,
      categoryId: map['categoryId'],
      tagIds: map['tagIds'] != null && map['tagIds'].isNotEmpty
          ? map['tagIds'].split(',').map<int>((e) => int.parse(e)).toList()
          : [],
      recurrenceRuleId: map['recurrenceRuleId'],
      parentRecurringId: map['parentRecurringId'],
      richDescription: map['richDescription'],
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      estimatedDuration: map['estimatedDuration'] ?? 0,
      actualDuration: map['actualDuration'],
      tags: map['tags'] != null && map['tags'].isNotEmpty
          ? map['tags'].split(',').where((e) => e.isNotEmpty).toList()
          : [],
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    Priority? priority,
    bool? isCompleted,
    int? categoryId,
    List<int>? tagIds,
    int? recurrenceRuleId,
    int? parentRecurringId,
    String? richDescription,
    DateTime? completedAt,
    int? estimatedDuration,
    int? actualDuration,
    List<String>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
      parentRecurringId: parentRecurringId ?? this.parentRecurringId,
      richDescription: richDescription ?? this.richDescription,
      completedAt: completedAt ?? this.completedAt,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      tags: tags ?? this.tags,
    );
  }
}

enum Priority {
  low,
  medium,
  high,
}

extension PriorityExtension on Priority {
  String get name {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  String get color {
    switch (this) {
      case Priority.low:
        return 'green';
      case Priority.medium:
        return 'orange';
      case Priority.high:
        return 'red';
    }
  }
}
