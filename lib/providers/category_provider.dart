import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Category> _categories = [];
  List<Tag> _tags = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  List<Tag> get tags => _tags;
  bool get isLoading => _isLoading;

  Future<void> loadCategoriesAndTags() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _databaseService.getAllCategories();
      _tags = await _databaseService.getAllTags();
    } catch (e) {
      print('Error loading categories and tags: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Category methods
  Future<void> addCategory(Category category) async {
    try {
      final id = await _databaseService.insertCategory(category);
      final newCategory = category.copyWith(id: id);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _databaseService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _databaseService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  Category? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Tag methods
  Future<void> addTag(Tag tag) async {
    try {
      final id = await _databaseService.insertTag(tag);
      final newTag = tag.copyWith(id: id);
      _tags.add(newTag);
      notifyListeners();
    } catch (e) {
      print('Error adding tag: $e');
    }
  }

  Future<void> updateTag(Tag tag) async {
    try {
      await _databaseService.updateTag(tag);
      final index = _tags.indexWhere((t) => t.id == tag.id);
      if (index != -1) {
        _tags[index] = tag;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating tag: $e');
    }
  }

  Future<void> deleteTag(int id) async {
    try {
      await _databaseService.deleteTag(id);
      _tags.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting tag: $e');
    }
  }

  Tag? getTagById(int? id) {
    if (id == null) return null;
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Tag> getTagsByIds(List<int> ids) {
    return _tags.where((tag) => ids.contains(tag.id)).toList();
  }
}