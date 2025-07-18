import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import '../models/todo_model.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../models/goal_model.dart';
import '../models/achievement_model.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();

  Future<String> createBackup() async {
    try {
      final data = await _getAllData();
      final jsonString = jsonEncode(data);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'todo_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<void> restoreFromBackup(String backupData) async {
    try {
      final data = jsonDecode(backupData) as Map<String, dynamic>;
      await _restoreAllData(data);
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  Future<String> exportToCSV() async {
    try {
      final todos = await _databaseService.getAllTodos();
      final categories = await _databaseService.getAllCategories();
      final tags = await _databaseService.getAllTags();
      
      // Create category and tag lookup maps
      final categoryMap = {for (var c in categories) c.id: c.name};
      final tagMap = {for (var t in tags) t.id: t.name};
      
      final csvRows = <String>[];
      
      // CSV Header
      csvRows.add('ID,Title,Description,Priority,Status,Category,Tags,Created,Due Date,Completed,Estimated Duration,Actual Duration');
      
      // CSV Data
      for (final todo in todos) {
        final categoryName = todo.categoryId != null ? categoryMap[todo.categoryId] ?? '' : '';
        final tagNames = todo.tagIds.map((id) => tagMap[id] ?? '').where((name) => name.isNotEmpty).join(';');
        
        final row = [
          todo.id?.toString() ?? '',
          _escapeCsvField(todo.title),
          _escapeCsvField(todo.description),
          todo.priority.name,
          todo.isCompleted ? 'Completed' : 'Pending',
          _escapeCsvField(categoryName),
          _escapeCsvField(tagNames),
          DateFormat('yyyy-MM-dd HH:mm').format(todo.createdAt),
          todo.dueDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(todo.dueDate!) : '',
          todo.completedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(todo.completedAt!) : '',
          todo.estimatedDuration.toString(),
          todo.actualDuration?.toString() ?? '',
        ];
        
        csvRows.add(row.join(','));
      }
      
      final csvContent = csvRows.join('\n');
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'todo_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvContent);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  Future<String> exportToPDF() async {
    // This would require pdf package, for now return a placeholder
    // In a real implementation, you would use packages like pdf or printing
    throw UnimplementedError('PDF export requires additional PDF package');
  }

  Future<void> autoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getString('last_auto_backup');
      final now = DateTime.now();
      
      if (lastBackup == null || 
          now.difference(DateTime.parse(lastBackup)).inDays >= 1) {
        
        await createBackup();
        await prefs.setString('last_auto_backup', now.toIso8601String());
        
        // Keep only last 7 auto backups
        await _cleanupOldBackups();
      }
    } catch (e) {
      print('Auto backup failed: $e');
    }
  }

  Future<List<String>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      return files
          .where((file) => file is File && file.path.contains('todo_backup_'))
          .map((file) => file.path)
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort by newest first
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getAllData() async {
    final todos = await _databaseService.getAllTodos();
    final categories = await _databaseService.getAllCategories();
    final tags = await _databaseService.getAllTags();
    final goals = await _databaseService.getAllGoals();
    final habits = await _databaseService.getAllHabitTrackers();
    final achievements = await _databaseService.getAllAchievements();
    final userProfile = await _databaseService.getUserProfile();
    
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      settings[key] = value;
    }
    
    return {
      'version': '2.0',
      'exportDate': DateTime.now().toIso8601String(),
      'todos': todos.map((t) => t.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'tags': tags.map((t) => t.toMap()).toList(),
      'goals': goals.map((g) => g.toMap()).toList(),
      'habitTrackers': habits.map((h) => h.toMap()).toList(),
      'achievements': achievements.map((a) => a.toMap()).toList(),
      'userProfile': userProfile?.toMap(),
      'settings': settings,
    };
  }

  Future<void> _restoreAllData(Map<String, dynamic> data) async {
    // Clear existing data (optional - you might want to merge instead)
    // For safety, we'll keep existing data and only add new items
    
    // Restore categories
    if (data['categories'] != null) {
      for (final categoryData in data['categories']) {
        final category = Category.fromMap(categoryData);
        try {
          await _databaseService.insertCategory(category.copyWith(id: null));
        } catch (e) {
          // Category might already exist, skip
        }
      }
    }
    
    // Restore tags
    if (data['tags'] != null) {
      for (final tagData in data['tags']) {
        final tag = Tag.fromMap(tagData);
        try {
          await _databaseService.insertTag(tag.copyWith(id: null));
        } catch (e) {
          // Tag might already exist, skip
        }
      }
    }
    
    // Restore todos
    if (data['todos'] != null) {
      for (final todoData in data['todos']) {
        final todo = Todo.fromMap(todoData);
        try {
          await _databaseService.insertTodo(todo.copyWith(id: null));
        } catch (e) {
          // Handle error
        }
      }
    }
    
    // Restore goals
    if (data['goals'] != null) {
      for (final goalData in data['goals']) {
        final goal = Goal.fromMap(goalData);
        try {
          await _databaseService.insertGoal(goal.copyWith(id: null));
        } catch (e) {
          // Handle error
        }
      }
    }
    
    // Restore habit trackers
    if (data['habitTrackers'] != null) {
      for (final habitData in data['habitTrackers']) {
        final habit = HabitTracker.fromMap(habitData);
        try {
          await _databaseService.insertHabitTracker(habit.copyWith(id: null));
        } catch (e) {
          // Handle error
        }
      }
    }
    
    // Restore user profile
    if (data['userProfile'] != null) {
      final profile = UserProfile.fromMap(data['userProfile']);
      await _databaseService.insertOrUpdateUserProfile(profile);
    }
    
    // Restore settings
    if (data['settings'] != null) {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data['settings'].entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final backups = await getAvailableBackups();
      if (backups.length > 7) {
        // Delete oldest backups, keep only 7 most recent
        for (int i = 7; i < backups.length; i++) {
          final file = File(backups[i]);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Failed to cleanup old backups: $e');
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Statistics and analytics export
  Future<String> exportAnalyticsReport() async {
    try {
      final todos = await _databaseService.getAllTodos();
      final goals = await _databaseService.getAllGoals();
      final habits = await _databaseService.getAllHabitTrackers();
      final profile = await _databaseService.getUserProfile();
      
      final report = _generateAnalyticsReport(todos, goals, habits, profile);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'analytics_report_$timestamp.txt';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(report);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export analytics report: $e');
    }
  }

  String _generateAnalyticsReport(List<Todo> todos, List<Goal> goals, 
      List<HabitTracker> habits, UserProfile? profile) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    
    buffer.writeln('📊 PRODUCTIVITY ANALYTICS REPORT');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // User Profile Section
    if (profile != null) {
      buffer.writeln('👤 USER PROFILE');
      buffer.writeln('Level: ${profile.level}');
      buffer.writeln('Total Points: ${profile.totalPoints}');
      buffer.writeln('Current Streak: ${profile.currentStreak} days');
      buffer.writeln('Longest Streak: ${profile.longestStreak} days');
      buffer.writeln();
    }
    
    // Tasks Overview
    buffer.writeln('📋 TASKS OVERVIEW');
    buffer.writeln('Total Tasks: ${todos.length}');
    buffer.writeln('Completed: ${todos.where((t) => t.isCompleted).length}');
    buffer.writeln('Pending: ${todos.where((t) => !t.isCompleted).length}');
    final overdue = todos.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now)).length;
    buffer.writeln('Overdue: $overdue');
    buffer.writeln();
    
    // Priority Breakdown
    buffer.writeln('🎯 PRIORITY BREAKDOWN');
    for (final priority in Priority.values) {
      final count = todos.where((t) => t.priority == priority).length;
      final completed = todos.where((t) => t.priority == priority && t.isCompleted).length;
      buffer.writeln('${priority.name}: $count total ($completed completed)');
    }
    buffer.writeln();
    
    // Goals Section
    buffer.writeln('🎯 GOALS OVERVIEW');
    buffer.writeln('Total Goals: ${goals.length}');
    buffer.writeln('Completed: ${goals.where((g) => g.isCompleted).length}');
    buffer.writeln('Active: ${goals.where((g) => !g.isCompleted).length}');
    buffer.writeln();
    
    // Habits Section
    buffer.writeln('🔄 HABITS OVERVIEW');
    buffer.writeln('Total Habits: ${habits.length}');
    buffer.writeln('Active: ${habits.where((h) => h.isActive).length}');
    final todayCompleted = habits.where((h) => h.isCompletedToday()).length;
    buffer.writeln('Completed Today: $todayCompleted');
    buffer.writeln();
    
    return buffer.toString();
  }
}