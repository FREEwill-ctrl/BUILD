import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../models/recurring_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  String _searchQuery = '';
  Priority? _filterPriority;
  bool? _filterCompleted;
  int? _filterCategoryId;
  List<int> _filterTagIds = [];
  bool _isLoading = false;

  List<Todo> get todos => _filteredTodos;
  String get searchQuery => _searchQuery;
  Priority? get filterPriority => _filterPriority;
  bool? get filterCompleted => _filterCompleted;
  int? get filterCategoryId => _filterCategoryId;
  List<int> get filterTagIds => _filterTagIds;
  bool get isLoading => _isLoading;

  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  int get lowPriorityTodos => _todos.where((todo) => todo.priority == Priority.low).length;
  int get mediumPriorityTodos => _todos.where((todo) => todo.priority == Priority.medium).length;
  int get highPriorityTodos => _todos.where((todo) => todo.priority == Priority.high).length;

  int get completedLowPriority => _todos.where((todo) => todo.priority == Priority.low && todo.isCompleted).length;
  int get completedMediumPriority => _todos.where((todo) => todo.priority == Priority.medium && todo.isCompleted).length;
  int get completedHighPriority => _todos.where((todo) => todo.priority == Priority.high && todo.isCompleted).length;

  /// Statistik penyelesaian harian 7 hari terakhir
  Map<DateTime, int> get completedPerDay {
    final now = DateTime.now();
    final Map<DateTime, int> data = {};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      data[day] = _todos.where((todo) => todo.isCompleted && todo.dueDate != null &&
        todo.dueDate!.year == day.year && todo.dueDate!.month == day.month && todo.dueDate!.day == day.day).length;
    }
    return data;
  }

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _databaseService.getAllTodos();
      _applyFilters();
    } catch (e) {
      print('Error loading todos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo(Todo todo) async {
    try {
      final id = await _databaseService.insertTodo(todo);
      final newTodo = todo.copyWith(id: id);
      _todos.add(newTodo);

      // Schedule notification if due date is set
      if (newTodo.dueDate != null) {
        await _notificationService.scheduleTaskReminder(newTodo);
      }

      _applyFilters();
      notifyListeners();
    } catch (e) {
      print('Error adding todo: $e');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      await _databaseService.updateTodo(todo);
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;

        // Update notification
        if (todo.id != null) {
          await _notificationService.cancelNotification(todo.id!);
          if (todo.dueDate != null && !todo.isCompleted) {
            await _notificationService.scheduleTaskReminder(todo);
          }
        }

        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating todo: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _databaseService.deleteTodo(id);
      await _notificationService.cancelNotification(id);
      _todos.removeWhere((todo) => todo.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      print('Error deleting todo: $e');
    }
  }

  Future<void> toggleTodoComplete(Todo todo) async {
    final now = DateTime.now();
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? now : null,
    );
    await updateTodo(updatedTodo);
  }

  void searchTodos(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByPriority(Priority? priority) {
    _filterPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  void filterByCompleted(bool? completed) {
    _filterCompleted = completed;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(int? categoryId) {
    _filterCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void filterByTags(List<int> tagIds) {
    _filterTagIds = tagIds;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterPriority = null;
    _filterCompleted = null;
    _filterCategoryId = null;
    _filterTagIds = [];
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTodos = _todos.where((todo) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!todo.title.toLowerCase().contains(query) &&
            !todo.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Priority filter
      if (_filterPriority != null && todo.priority != _filterPriority) {
        return false;
      }

      // Completed filter
      if (_filterCompleted != null && todo.isCompleted != _filterCompleted) {
        return false;
      }

      // Category filter
      if (_filterCategoryId != null && todo.categoryId != _filterCategoryId) {
        return false;
      }

      // Tags filter
      if (_filterTagIds.isNotEmpty) {
        final hasMatchingTag = _filterTagIds.any((tagId) => todo.tagIds.contains(tagId));
        if (!hasMatchingTag) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by due date and priority
    _filteredTodos.sort((a, b) {
      // Completed tasks go to bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Sort by due date (closest first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // Sort by priority (high first)
      return b.priority.index.compareTo(a.priority.index);
    });
  }

  Future<Todo?> getTodoById(int id) async {
    try {
      return await _databaseService.getTodoById(id);
    } catch (e) {
      print('Error getting todo by id: $e');
      return null;
    }
  }

  // Recurring tasks methods
  Future<void> createRecurringTodoInstance(Todo recurringTodo, RecurrenceRule rule) async {
    try {
      final nextDueDate = rule.getNextOccurrence(recurringTodo.dueDate ?? DateTime.now());
      if (nextDueDate == null) return;

      final newTodo = recurringTodo.copyWith(
        id: null,
        dueDate: nextDueDate,
        isCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
        parentRecurringId: recurringTodo.id,
      );

      await addTodo(newTodo);
    } catch (e) {
      print('Error creating recurring todo instance: $e');
    }
  }

  Future<void> checkAndCreateRecurringTodos() async {
    try {
      final recurringTodos = _todos.where((todo) => 
          todo.recurrenceRuleId != null && 
          todo.isCompleted && 
          todo.parentRecurringId == null).toList();

      for (final todo in recurringTodos) {
        final rule = await _databaseService.getRecurrenceRuleById(todo.recurrenceRuleId!);
        if (rule != null) {
          await createRecurringTodoInstance(todo, rule);
        }
      }
    } catch (e) {
      print('Error checking recurring todos: $e');
    }
  }

  // Enhanced analytics
  Map<String, dynamic> getAdvancedAnalytics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);

    final todayTodos = _todos.where((t) => 
        t.createdAt.isAfter(today) || 
        (t.dueDate != null && t.dueDate!.isAfter(today) && t.dueDate!.isBefore(today.add(const Duration(days: 1))))).length;
    
    final thisWeekCompleted = _todos.where((t) => 
        t.isCompleted && t.completedAt != null && t.completedAt!.isAfter(thisWeek)).length;
    
    final thisMonthCompleted = _todos.where((t) => 
        t.isCompleted && t.completedAt != null && t.completedAt!.isAfter(thisMonth)).length;

    final averageCompletionTime = _getAverageCompletionTime();
    final productivity = _getProductivityScore();

    return {
      'todayTodos': todayTodos,
      'thisWeekCompleted': thisWeekCompleted,
      'thisMonthCompleted': thisMonthCompleted,
      'averageCompletionTimeHours': averageCompletionTime,
      'productivityScore': productivity,
      'categoriesUsed': _todos.map((t) => t.categoryId).where((c) => c != null).toSet().length,
      'tagsUsed': _todos.expand((t) => t.tagIds).toSet().length,
      'overdueTasks': _todos.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now)).length,
    };
  }

  double _getAverageCompletionTime() {
    final completedTodos = _todos.where((t) => t.isCompleted && t.completedAt != null).toList();
    if (completedTodos.isEmpty) return 0.0;

    final totalHours = completedTodos.map((t) => 
        t.completedAt!.difference(t.createdAt).inHours).reduce((a, b) => a + b);
    
    return totalHours / completedTodos.length;
  }

  double _getProductivityScore() {
    final total = _todos.length;
    if (total == 0) return 0.0;

    final completed = completedTodos;
    final onTime = completed.where((t) => 
        t.dueDate == null || (t.completedAt != null && t.completedAt!.isBefore(t.dueDate!))).length;
    
    final baseScore = completed.length / total * 100;
    final timeBonus = total > 0 ? (onTime / total) * 20 : 0;
    
    return (baseScore + timeBonus).clamp(0.0, 100.0);
  }

  // Utility methods
  List<Todo> getTodosByCategory(int? categoryId) {
    return _todos.where((t) => t.categoryId == categoryId).toList();
  }

  List<Todo> getTodosByTag(int tagId) {
    return _todos.where((t) => t.tagIds.contains(tagId)).toList();
  }

  List<Todo> getOverdueTodos() {
    final now = DateTime.now();
    return _todos.where((t) => 
        !t.isCompleted && 
        t.dueDate != null && 
        t.dueDate!.isBefore(now)).toList();
  }

  List<Todo> getTodayTodos() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _todos.where((t) => 
        t.dueDate != null && 
        t.dueDate!.isAfter(today) && 
        t.dueDate!.isBefore(tomorrow)).toList();
  }

  List<Todo> getUpcomingTodos({int days = 7}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    
    return _todos.where((t) => 
        !t.isCompleted &&
        t.dueDate != null && 
        t.dueDate!.isAfter(now) && 
        t.dueDate!.isBefore(cutoff)).toList();
  }
}
