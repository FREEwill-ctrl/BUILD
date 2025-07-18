import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String color;
  final String iconCodePoint;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    required this.color,
    required this.iconCodePoint,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      iconCodePoint: map['iconCodePoint'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? color,
    String? iconCodePoint,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get icon {
    return IconData(int.parse(iconCodePoint), fontFamily: 'MaterialIcons');
  }

  Color get colorValue {
    return Color(int.parse('0xFF$color'));
  }
}

// Default categories
class DefaultCategories {
  static List<Category> get defaultList => [
    Category(
      name: 'Work',
      color: '2196F3',
      iconCodePoint: '0xe164',
      createdAt: DateTime.now(),
    ),
    Category(
      name: 'Personal',
      color: '4CAF50',
      iconCodePoint: '0xe7fd',
      createdAt: DateTime.now(),
    ),
    Category(
      name: 'Health',
      color: 'FF9800',
      iconCodePoint: '0xe87c',
      createdAt: DateTime.now(),
    ),
    Category(
      name: 'Learning',
      color: '9C27B0',
      iconCodePoint: '0xe80c',
      createdAt: DateTime.now(),
    ),
    Category(
      name: 'Finance',
      color: 'F44336',
      iconCodePoint: '0xe263',
      createdAt: DateTime.now(),
    ),
  ];
}