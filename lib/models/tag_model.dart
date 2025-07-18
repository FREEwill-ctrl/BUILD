import 'package:flutter/material.dart';

class Tag {
  final int? id;
  final String name;
  final String color;
  final DateTime createdAt;

  Tag({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Tag copyWith({
    int? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Color get colorValue {
    return Color(int.parse('0xFF$color'));
  }
}

// Default tags
class DefaultTags {
  static List<Tag> get defaultList => [
    Tag(
      name: 'Important',
      color: 'F44336',
      createdAt: DateTime.now(),
    ),
    Tag(
      name: 'Urgent',
      color: 'FF9800',
      createdAt: DateTime.now(),
    ),
    Tag(
      name: 'Quick',
      color: '4CAF50',
      createdAt: DateTime.now(),
    ),
    Tag(
      name: 'Meeting',
      color: '2196F3',
      createdAt: DateTime.now(),
    ),
    Tag(
      name: 'Call',
      color: '9C27B0',
      createdAt: DateTime.now(),
    ),
    Tag(
      name: 'Email',
      color: '607D8B',
      createdAt: DateTime.now(),
    ),
  ];
}