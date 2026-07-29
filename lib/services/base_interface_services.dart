abstract class IBaseService<T> {
  Future<List<T>> getAll({int page = 0, int limit = 10});

  Future<T?> getById(String id);

  Future<T> create(T item);

  Future<T> update(T item);

  Future<void> delete(String id);
}
