import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/time_entry_model.dart';
import '../services/database_service.dart';

class TimeTrackingProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  Map<int, TimeEntry?> _activeTimeEntries = {};
  Map<int, List<TimeEntry>> _todoTimeEntries = {};
  Timer? _timer;
  bool _isLoading = false;

  Map<int, TimeEntry?> get activeTimeEntries => _activeTimeEntries;
  Map<int, List<TimeEntry>> get todoTimeEntries => _todoTimeEntries;
  bool get isLoading => _isLoading;

  Future<void> loadTimeEntriesForTodo(int todoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final entries = await _databaseService.getTimeEntriesForTodo(todoId);
      _todoTimeEntries[todoId] = entries;
      
      // Check for active time entry
      final activeEntry = await _databaseService.getActiveTimeEntry(todoId);
      _activeTimeEntries[todoId] = activeEntry;
      
      if (activeEntry != null) {
        _startTimer();
      }
    } catch (e) {
      print('Error loading time entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startTimeTracking(int todoId, {String? description}) async {
    try {
      // Stop any existing active tracking for this todo
      await stopTimeTracking(todoId);

      final now = DateTime.now();
      final timeEntry = TimeEntry(
        todoId: todoId,
        startTime: now,
        description: description,
        createdAt: now,
      );

      final id = await _databaseService.insertTimeEntry(timeEntry);
      final newTimeEntry = timeEntry.copyWith(id: id);
      
      _activeTimeEntries[todoId] = newTimeEntry;
      
      // Add to todo time entries list
      if (_todoTimeEntries[todoId] == null) {
        _todoTimeEntries[todoId] = [];
      }
      _todoTimeEntries[todoId]!.insert(0, newTimeEntry);
      
      _startTimer();
      notifyListeners();
    } catch (e) {
      print('Error starting time tracking: $e');
    }
  }

  Future<void> stopTimeTracking(int todoId) async {
    try {
      final activeEntry = _activeTimeEntries[todoId];
      if (activeEntry != null) {
        final now = DateTime.now();
        final duration = now.difference(activeEntry.startTime);
        
        final updatedEntry = activeEntry.copyWith(
          endTime: now,
          duration: duration,
        );

        await _databaseService.updateTimeEntry(updatedEntry);
        
        // Update in memory
        _activeTimeEntries[todoId] = null;
        
        // Update in todo time entries list
        if (_todoTimeEntries[todoId] != null) {
          final index = _todoTimeEntries[todoId]!.indexWhere((e) => e.id == activeEntry.id);
          if (index != -1) {
            _todoTimeEntries[todoId]![index] = updatedEntry;
          }
        }
        
        _stopTimer();
        notifyListeners();
      }
    } catch (e) {
      print('Error stopping time tracking: $e');
    }
  }

  Future<void> pauseTimeTracking(int todoId) async {
    await stopTimeTracking(todoId);
  }

  Future<void> resumeTimeTracking(int todoId) async {
    await startTimeTracking(todoId);
  }

  Duration getTotalTimeSpent(int todoId) {
    final entries = _todoTimeEntries[todoId] ?? [];
    Duration total = Duration.zero;
    
    for (final entry in entries) {
      total += entry.actualDuration;
    }
    
    return total;
  }

  String getFormattedTotalTime(int todoId) {
    final duration = getTotalTimeSpent(todoId);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  bool isTracking(int todoId) {
    return _activeTimeEntries[todoId] != null;
  }

  String? getCurrentSessionTime(int todoId) {
    final activeEntry = _activeTimeEntries[todoId];
    if (activeEntry != null) {
      return activeEntry.formattedDuration;
    }
    return null;
  }

  void _startTimer() {
    if (_timer != null) return; // Timer already running
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners(); // Update UI to show current running time
    });
  }

  void _stopTimer() {
    // Only stop timer if no active entries exist
    if (_activeTimeEntries.values.every((entry) => entry == null)) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> deleteTimeEntry(int todoId, int entryId) async {
    try {
      await _databaseService.deleteTimeEntry(entryId);
      
      // Remove from active if it was active
      if (_activeTimeEntries[todoId]?.id == entryId) {
        _activeTimeEntries[todoId] = null;
        _stopTimer();
      }
      
      // Remove from todo time entries
      _todoTimeEntries[todoId]?.removeWhere((entry) => entry.id == entryId);
      
      notifyListeners();
    } catch (e) {
      print('Error deleting time entry: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Analytics methods
  Map<String, Duration> getTimeAnalytics() {
    final analytics = <String, Duration>{};
    
    for (final entries in _todoTimeEntries.values) {
      for (final entry in entries) {
        final date = entry.startTime.toIso8601String().substring(0, 10);
        analytics[date] = (analytics[date] ?? Duration.zero) + entry.actualDuration;
      }
    }
    
    return analytics;
  }

  Duration getTodayTotalTime() {
    final today = DateTime.now();
    final todayKey = today.toIso8601String().substring(0, 10);
    return getTimeAnalytics()[todayKey] ?? Duration.zero;
  }

  Duration getWeekTotalTime() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    Duration total = Duration.zero;
    
    for (final entries in _todoTimeEntries.values) {
      for (final entry in entries) {
        if (entry.startTime.isAfter(weekStart)) {
          total += entry.actualDuration;
        }
      }
    }
    
    return total;
  }
}