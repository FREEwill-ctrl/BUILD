import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_model.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../models/time_entry_model.dart';
import '../models/recurring_model.dart';
import '../models/goal_model.dart';
import '../models/achievement_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAllTables(db);
      await _migrateExistingData(db);
    }
  }

  Future<void> _createAllTables(Database db) async {
    // Categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        iconCodePoint TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Recurrence rules table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurrence_rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        interval INTEGER DEFAULT 1,
        daysOfWeek TEXT,
        dayOfMonth INTEGER,
        endDate INTEGER,
        maxOccurrences INTEGER,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Enhanced todos table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        dueDate INTEGER,
        priority INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL,
        categoryId INTEGER,
        tagIds TEXT,
        recurrenceRuleId INTEGER,
        parentRecurringId INTEGER,
        richDescription TEXT,
        completedAt INTEGER,
        estimatedDuration INTEGER DEFAULT 0,
        actualDuration INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (recurrenceRuleId) REFERENCES recurrence_rules (id)
      )
    ''');

    // Time entries table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS time_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todoId INTEGER NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        duration INTEGER,
        description TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (todoId) REFERENCES todos (id)
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        targetDate INTEGER NOT NULL,
        targetValue INTEGER NOT NULL,
        currentValue INTEGER DEFAULT 0,
        type INTEGER NOT NULL,
        unit TEXT,
        createdAt INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    // Habit trackers table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habit_trackers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        completedDates TEXT,
        targetFrequency INTEGER DEFAULT 7,
        createdAt INTEGER NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        iconPath TEXT NOT NULL,
        unlockedAt INTEGER,
        points INTEGER NOT NULL,
        type INTEGER NOT NULL,
        criteria TEXT,
        isUnlocked INTEGER DEFAULT 0
      )
    ''');

    // User profile table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile(
        id INTEGER PRIMARY KEY DEFAULT 1,
        totalPoints INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        achievementIds TEXT,
        statistics TEXT,
        currentStreak INTEGER DEFAULT 0,
        longestStreak INTEGER DEFAULT 0,
        lastActiveDate INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _migrateExistingData(Database db) async {
    // Add new columns to existing todos table if upgrading from version 1
    try {
      await db.execute('ALTER TABLE todos ADD COLUMN categoryId INTEGER');
      await db.execute('ALTER TABLE todos ADD COLUMN tagIds TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN recurrenceRuleId INTEGER');
      await db.execute('ALTER TABLE todos ADD COLUMN parentRecurringId INTEGER');
      await db.execute('ALTER TABLE todos ADD COLUMN richDescription TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN completedAt INTEGER');
      await db.execute('ALTER TABLE todos ADD COLUMN estimatedDuration INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE todos ADD COLUMN actualDuration INTEGER');
    } catch (e) {
      // Columns might already exist, ignore errors
    }
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<Todo>> getAllTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos');
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<Todo?> getTodoById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Todo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Todo>> searchTodos(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<List<Todo>> getTodosByPriority(Priority priority) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'priority = ?',
      whereArgs: [priority.index],
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<List<Todo>> getCompletedTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<List<Todo>> getPendingTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'isCompleted = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  // Categories CRUD
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tags CRUD
  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert('tags', tag.toMap());
  }

  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tags');
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  Future<Tag?> getTagById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Tag.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTag(Tag tag) async {
    final db = await database;
    return await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<int> deleteTag(int id) async {
    final db = await database;
    return await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Time Entries CRUD
  Future<int> insertTimeEntry(TimeEntry timeEntry) async {
    final db = await database;
    return await db.insert('time_entries', timeEntry.toMap());
  }

  Future<List<TimeEntry>> getTimeEntriesForTodo(int todoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'todoId = ?',
      whereArgs: [todoId],
      orderBy: 'startTime DESC',
    );
    return List.generate(maps.length, (i) => TimeEntry.fromMap(maps[i]));
  }

  Future<TimeEntry?> getActiveTimeEntry(int todoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'todoId = ? AND endTime IS NULL',
      whereArgs: [todoId],
    );
    if (maps.isNotEmpty) {
      return TimeEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTimeEntry(TimeEntry timeEntry) async {
    final db = await database;
    return await db.update(
      'time_entries',
      timeEntry.toMap(),
      where: 'id = ?',
      whereArgs: [timeEntry.id],
    );
  }

  Future<int> deleteTimeEntry(int id) async {
    final db = await database;
    return await db.delete(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Recurrence Rules CRUD
  Future<int> insertRecurrenceRule(RecurrenceRule rule) async {
    final db = await database;
    return await db.insert('recurrence_rules', rule.toMap());
  }

  Future<RecurrenceRule?> getRecurrenceRuleById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurrence_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return RecurrenceRule.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRecurrenceRule(RecurrenceRule rule) async {
    final db = await database;
    return await db.update(
      'recurrence_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRecurrenceRule(int id) async {
    final db = await database;
    return await db.delete(
      'recurrence_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Goals CRUD
  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals', orderBy: 'targetDate ASC');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  Future<Goal?> getGoalById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Goal.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Habit Trackers CRUD
  Future<int> insertHabitTracker(HabitTracker habit) async {
    final db = await database;
    return await db.insert('habit_trackers', habit.toMap());
  }

  Future<List<HabitTracker>> getAllHabitTrackers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habit_trackers', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => HabitTracker.fromMap(maps[i]));
  }

  Future<HabitTracker?> getHabitTrackerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_trackers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return HabitTracker.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHabitTracker(HabitTracker habit) async {
    final db = await database;
    return await db.update(
      'habit_trackers',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabitTracker(int id) async {
    final db = await database;
    return await db.delete(
      'habit_trackers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Achievements CRUD
  Future<int> insertAchievement(Achievement achievement) async {
    final db = await database;
    return await db.insert('achievements', achievement.toMap());
  }

  Future<List<Achievement>> getAllAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('achievements', orderBy: 'points ASC');
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  Future<Achievement?> getAchievementById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Achievement.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAchievement(Achievement achievement) async {
    final db = await database;
    return await db.update(
      'achievements',
      achievement.toMap(),
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  // User Profile CRUD
  Future<int> insertOrUpdateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  // Initialize default data
  Future<void> initializeDefaultData() async {
    // Insert default categories
    final categories = await getAllCategories();
    if (categories.isEmpty) {
      for (final category in DefaultCategories.defaultList) {
        await insertCategory(category);
      }
    }

    // Insert default tags
    final tags = await getAllTags();
    if (tags.isEmpty) {
      for (final tag in DefaultTags.defaultList) {
        await insertTag(tag);
      }
    }

    // Insert default achievements
    final achievements = await getAllAchievements();
    if (achievements.isEmpty) {
      for (final achievement in DefaultAchievements.defaultList) {
        await insertAchievement(achievement);
      }
    }

    // Create default user profile
    final profile = await getUserProfile();
    if (profile == null) {
      final now = DateTime.now();
      await insertOrUpdateUserProfile(UserProfile(
        lastActiveDate: now,
        createdAt: now,
      ));
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
