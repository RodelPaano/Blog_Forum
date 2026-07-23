import '../core/exceptions.dart';

/// Generic CRUD scaffolding — specialized repos extend this.
abstract class GenericRepository<T> {
  Future<List<T>> getAll({int page = 0, int limit = 10});
  Future<T?> getById(String id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(String id);

  /// Centralized error mapping (no raw exceptions escape).
  AppException mapError(Object e) {
    if (e is AppException) return e;
    return DatabaseException('Unexpected database error');
  }
}
