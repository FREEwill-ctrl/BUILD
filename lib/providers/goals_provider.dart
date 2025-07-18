import 'package:flutter/foundation.dart';
import '../models/goal_model.dart';
import '../services/database_service.dart';

class GoalsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Goal> _goals = [];
  List<HabitTracker> _habitTrackers = [];
  bool _isLoading = false;

  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  List<Goal> get overdueGoals => _goals.where((g) => g.isOverdue).toList();
  
  List<HabitTracker> get habitTrackers => _habitTrackers;
  List<HabitTracker> get activeHabits => _habitTrackers.where((h) => h.isActive).toList();
  
  bool get isLoading => _isLoading;

  Future<void> loadGoalsAndHabits() async {
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await _databaseService.getAllGoals();
      _habitTrackers = await _databaseService.getAllHabitTrackers();
    } catch (e) {
      print('Error loading goals and habits: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Goals methods
  Future<void> addGoal(Goal goal) async {
    try {
      final id = await _databaseService.insertGoal(goal);
      final newGoal = goal.copyWith(id: id);
      _goals.add(newGoal);
      _sortGoals();
      notifyListeners();
    } catch (e) {
      print('Error adding goal: $e');
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _databaseService.updateGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        _sortGoals();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating goal: $e');
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _databaseService.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  Future<void> incrementGoalProgress(int goalId, {int increment = 1}) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final newValue = goal.currentValue + increment;
    final isCompleted = newValue >= goal.targetValue;
    
    final updatedGoal = goal.copyWith(
      currentValue: newValue,
      isCompleted: isCompleted,
    );
    
    await updateGoal(updatedGoal);
  }

  Future<void> setGoalProgress(int goalId, int value) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final isCompleted = value >= goal.targetValue;
    
    final updatedGoal = goal.copyWith(
      currentValue: value,
      isCompleted: isCompleted,
    );
    
    await updateGoal(updatedGoal);
  }

  void _sortGoals() {
    _goals.sort((a, b) {
      // Completed goals go to bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Sort by target date
      return a.targetDate.compareTo(b.targetDate);
    });
  }

  // Habit tracker methods
  Future<void> addHabitTracker(HabitTracker habit) async {
    try {
      final id = await _databaseService.insertHabitTracker(habit);
      final newHabit = habit.copyWith(id: id);
      _habitTrackers.add(newHabit);
      notifyListeners();
    } catch (e) {
      print('Error adding habit tracker: $e');
    }
  }

  Future<void> updateHabitTracker(HabitTracker habit) async {
    try {
      await _databaseService.updateHabitTracker(habit);
      final index = _habitTrackers.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habitTrackers[index] = habit;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating habit tracker: $e');
    }
  }

  Future<void> deleteHabitTracker(int id) async {
    try {
      await _databaseService.deleteHabitTracker(id);
      _habitTrackers.removeWhere((h) => h.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting habit tracker: $e');
    }
  }

  Future<void> markHabitComplete(int habitId, {DateTime? date}) async {
    date ??= DateTime.now();
    final habit = _habitTrackers.firstWhere((h) => h.id == habitId);
    
    // Normalize date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // Check if already completed today
    if (habit.completedDates.any((d) => 
        d.year == normalizedDate.year && 
        d.month == normalizedDate.month && 
        d.day == normalizedDate.day)) {
      return; // Already completed today
    }
    
    final updatedDates = [...habit.completedDates, normalizedDate];
    final updatedHabit = habit.copyWith(completedDates: updatedDates);
    
    await updateHabitTracker(updatedHabit);
  }

  Future<void> unmarkHabitComplete(int habitId, {DateTime? date}) async {
    date ??= DateTime.now();
    final habit = _habitTrackers.firstWhere((h) => h.id == habitId);
    
    // Normalize date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final updatedDates = habit.completedDates.where((d) => 
        !(d.year == normalizedDate.year && 
          d.month == normalizedDate.month && 
          d.day == normalizedDate.day)).toList();
    
    final updatedHabit = habit.copyWith(completedDates: updatedDates);
    
    await updateHabitTracker(updatedHabit);
  }

  Future<void> toggleHabitCompletion(int habitId, {DateTime? date}) async {
    final habit = _habitTrackers.firstWhere((h) => h.id == habitId);
    date ??= DateTime.now();
    
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isCompleted = habit.completedDates.any((d) => 
        d.year == normalizedDate.year && 
        d.month == normalizedDate.month && 
        d.day == normalizedDate.day);
    
    if (isCompleted) {
      await unmarkHabitComplete(habitId, date: date);
    } else {
      await markHabitComplete(habitId, date: date);
    }
  }

  // Analytics and insights
  Map<String, dynamic> getGoalsAnalytics() {
    final total = _goals.length;
    final completed = completedGoals.length;
    final active = activeGoals.length;
    final overdue = overdueGoals.length;
    
    return {
      'totalGoals': total,
      'completedGoals': completed,
      'activeGoals': active,
      'overdueGoals': overdue,
      'completionRate': total > 0 ? completed / total : 0.0,
      'overdueRate': total > 0 ? overdue / total : 0.0,
    };
  }

  Map<String, dynamic> getHabitsAnalytics() {
    final active = activeHabits;
    final totalHabits = active.length;
    
    if (totalHabits == 0) {
      return {
        'totalHabits': 0,
        'averageStreak': 0.0,
        'averageWeeklyCompletion': 0.0,
        'habitsCompletedToday': 0,
      };
    }
    
    final averageStreak = active.map((h) => h.currentStreak).reduce((a, b) => a + b) / totalHabits;
    final averageWeeklyCompletion = active.map((h) => h.weeklyProgress).reduce((a, b) => a + b) / totalHabits;
    final habitsCompletedToday = active.where((h) => h.isCompletedToday()).length;
    
    return {
      'totalHabits': totalHabits,
      'averageStreak': averageStreak,
      'averageWeeklyCompletion': averageWeeklyCompletion,
      'habitsCompletedToday': habitsCompletedToday,
    };
  }

  List<Goal> getGoalsByType(GoalType type) {
    return _goals.where((g) => g.type == type).toList();
  }

  List<Goal> getUpcomingGoals({int days = 7}) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return activeGoals.where((g) => g.targetDate.isBefore(cutoff)).toList();
  }

  HabitTracker? getHabitById(int id) {
    try {
      return _habitTrackers.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  Goal? getGoalById(int id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper methods for UI
  String getGoalProgressText(Goal goal) {
    return '${goal.currentValue}/${goal.targetValue} ${goal.displayUnit}';
  }

  String getHabitStreakText(HabitTracker habit) {
    final streak = habit.currentStreak;
    return streak == 1 ? '1 day streak' : '$streak days streak';
  }

  String getHabitWeeklyText(HabitTracker habit) {
    return '${habit.thisWeekCompletions}/${habit.targetFrequency} this week';
  }
}