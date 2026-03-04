import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category.dart';

/// Repository for managing categories in Firestore.
///
/// Categories are stored in the 'categories' collection.
/// Provides CRUD operations and seed functionality.
class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('categories');

  /// Get all categories, sorted by sortOrder
  Future<List<Category>> getAllCategories() async {
    final snapshot = await _collection.orderBy('sortOrder').get();
    if (snapshot.docs.isEmpty) {
      // Auto-seed if collection is empty
      await seedCategories();
      final seeded = await _collection.orderBy('sortOrder').get();
      return seeded.docs.map((doc) => Category.fromJson(doc.data())).toList();
    }
    return snapshot.docs.map((doc) => Category.fromJson(doc.data())).toList();
  }

  /// Get only active categories
  Future<List<Category>> getActiveCategories() async {
    final all = await getAllCategories();
    return all.where((c) => c.isActive).toList();
  }

  /// Get a single category by ID
  Future<Category?> getCategoryById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Category.fromJson(doc.data()!);
  }

  /// Create a new category
  Future<void> createCategory(Category category) async {
    await _collection.doc(category.id).set(category.toJson());
  }

  /// Update an existing category
  Future<void> updateCategory(Category category) async {
    await _collection.doc(category.id).update(category.toJson());
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await _collection.doc(id).delete();
  }

  /// Seed default categories if collection is empty
  Future<void> seedCategories() async {
    final batch = _firestore.batch();
    for (final category in Category.defaultCategories) {
      batch.set(_collection.doc(category.id), category.toJson());
    }
    await batch.commit();
  }

  /// Get category name by ID (with fallback)
  Future<String> getCategoryName(String id) async {
    final cat = await getCategoryById(id);
    return cat?.name ?? id;
  }

  /// Get category emoji by ID (with fallback)
  Future<String> getCategoryEmoji(String id) async {
    final cat = await getCategoryById(id);
    return cat?.emoji ?? '📍';
  }
}
