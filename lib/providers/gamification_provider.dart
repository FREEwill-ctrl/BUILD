import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../services/database_service.dart';

class GamificationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Achievement> _achievements = [];
  UserProfile? _userProfile;
  bool _isLoading = false;

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements => _achievements.where((a) => !a.isUnlocked).toList();
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  int get totalPoints => _userProfile?.totalPoints ?? 0;
  int get level => _userProfile?.level ?? 1;
  int get currentStreak => _userProfile?.currentStreak ?? 0;
  int get longestStreak => _userProfile?.longestStreak ?? 0;

  Future<void> loadGamificationData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _achievements = await _databaseService.getAllAchievements();
      _userProfile = await _databaseService.getUserProfile();
      
      if (_userProfile == null) {
        // Create default profile
        final now = DateTime.now();
        _userProfile = UserProfile(
          lastActiveDate: now,
          createdAt: now,
        );
        await _databaseService.insertOrUpdateUserProfile(_userProfile!);
      }
    } catch (e) {
      print('Error loading gamification data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPoints(int points, {String? reason}) async {
    if (_userProfile == null) return;

    try {
      final newTotalPoints = _userProfile!.totalPoints + points;
      final newLevel = (newTotalPoints / 100).floor() + 1;
      
      final updatedProfile = _userProfile!.copyWith(
        totalPoints: newTotalPoints,
        level: newLevel,
        lastActiveDate: DateTime.now(),
      );

      await _databaseService.insertOrUpdateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      
      // Update statistics
      await _updateStatistic('totalPointsEarned', points);
      
      // Check for new achievements
      await _checkAndUnlockAchievements();
      
      notifyListeners();
    } catch (e) {
      print('Error adding points: $e');
    }
  }

  Future<void> updateStreak(int newStreak) async {
    if (_userProfile == null) return;

    try {
      final longestStreak = newStreak > _userProfile!.longestStreak 
          ? newStreak 
          : _userProfile!.longestStreak;
      
      final updatedProfile = _userProfile!.copyWith(
        currentStreak: newStreak,
        longestStreak: longestStreak,
        lastActiveDate: DateTime.now(),
      );

      await _databaseService.insertOrUpdateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      
      // Check for streak achievements
      await _checkAndUnlockAchievements();
      
      notifyListeners();
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<void> recordTaskCompletion() async {
    await addPoints(10, reason: 'Task completed');
    await _updateStatistic('completedTasks', 1);
    await _updateStatistic('tasksCompletedToday', 1);
    
    // Check for early bird achievement (before 8 AM)
    final now = DateTime.now();
    if (now.hour < 8) {
      await _updateStatistic('earlyMorningTask', 1);
    }
    
    await _checkAndUnlockAchievements();
  }

  Future<void> recordPomodoroSession() async {
    await addPoints(5, reason: 'Pomodoro session completed');
    await _updateStatistic('pomodoroSessions', 1);
    await _checkAndUnlockAchievements();
  }

  Future<void> recordTimeTracked(Duration duration) async {
    final minutes = duration.inMinutes;
    await addPoints(minutes ~/ 5, reason: 'Time tracked'); // 1 point per 5 minutes
    await _updateStatistic('trackedMinutes', minutes);
    await _checkAndUnlockAchievements();
  }

  Future<void> _updateStatistic(String key, int increment) async {
    if (_userProfile == null) return;

    final currentStats = Map<String, int>.from(_userProfile!.statistics);
    currentStats[key] = (currentStats[key] ?? 0) + increment;
    
    final updatedProfile = _userProfile!.copyWith(statistics: currentStats);
    await _databaseService.insertOrUpdateUserProfile(updatedProfile);
    _userProfile = updatedProfile;
  }

  Future<void> _checkAndUnlockAchievements() async {
    if (_userProfile == null) return;

    final stats = _userProfile!.statistics;
    bool hasNewAchievements = false;

    for (final achievement in _achievements) {
      if (achievement.isUnlocked || achievement.criteria == null) continue;

      bool shouldUnlock = false;

      // Check achievement criteria
      if (achievement.criteria!.containsKey('completedTasks')) {
        final required = achievement.criteria!['completedTasks'] as int;
        final current = stats['completedTasks'] ?? 0;
        shouldUnlock = current >= required;
      } else if (achievement.criteria!.containsKey('streak')) {
        final required = achievement.criteria!['streak'] as int;
        shouldUnlock = _userProfile!.currentStreak >= required;
      } else if (achievement.criteria!.containsKey('trackedMinutes')) {
        final required = achievement.criteria!['trackedMinutes'] as int;
        final current = stats['trackedMinutes'] ?? 0;
        shouldUnlock = current >= required;
      } else if (achievement.criteria!.containsKey('pomodoroSessions')) {
        final required = achievement.criteria!['pomodoroSessions'] as int;
        final current = stats['pomodoroSessions'] ?? 0;
        shouldUnlock = current >= required;
      } else if (achievement.criteria!.containsKey('earlyMorningTask')) {
        final required = achievement.criteria!['earlyMorningTask'] as int;
        final current = stats['earlyMorningTask'] ?? 0;
        shouldUnlock = current >= required;
      }

      if (shouldUnlock) {
        await _unlockAchievement(achievement);
        hasNewAchievements = true;
      }
    }

    if (hasNewAchievements) {
      await loadGamificationData(); // Refresh data
    }
  }

  Future<void> _unlockAchievement(Achievement achievement) async {
    try {
      final unlockedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      await _databaseService.updateAchievement(unlockedAchievement);
      
      // Add achievement points to user profile
      await addPoints(achievement.points, reason: 'Achievement unlocked: ${achievement.name}');
      
      // Update achievements list
      final index = _achievements.indexWhere((a) => a.id == achievement.id);
      if (index != -1) {
        _achievements[index] = unlockedAchievement;
      }

      // Show achievement notification (you can implement this in UI)
      print('🏆 Achievement Unlocked: ${achievement.name} (+${achievement.points} points)');
      
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  // UI Helper methods
  double get levelProgress {
    if (_userProfile == null) return 0.0;
    return _userProfile!.levelProgress;
  }

  int get pointsToNextLevel {
    if (_userProfile == null) return 100;
    return _userProfile!.pointsToNextLevel;
  }

  Map<AchievementType, List<Achievement>> get achievementsByType {
    final grouped = <AchievementType, List<Achievement>>{};
    
    for (final achievement in _achievements) {
      if (!grouped.containsKey(achievement.type)) {
        grouped[achievement.type] = [];
      }
      grouped[achievement.type]!.add(achievement);
    }
    
    return grouped;
  }

  List<Achievement> getRecentAchievements({int limit = 5}) {
    final unlocked = unlockedAchievements;
    unlocked.sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return unlocked.take(limit).toList();
  }

  // Statistics
  Map<String, dynamic> getGameStats() {
    if (_userProfile == null) return {};
    
    return {
      'totalPoints': _userProfile!.totalPoints,
      'level': _userProfile!.level,
      'currentStreak': _userProfile!.currentStreak,
      'longestStreak': _userProfile!.longestStreak,
      'achievementsUnlocked': unlockedAchievements.length,
      'totalAchievements': _achievements.length,
      'completionRate': _achievements.isEmpty ? 0.0 : unlockedAchievements.length / _achievements.length,
      ..._userProfile!.statistics,
    };
  }
}