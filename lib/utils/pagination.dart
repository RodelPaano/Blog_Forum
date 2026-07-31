/// Reusable paginator that calls a [load] callback for each page.
class Paginator<T> {
  Paginator({required this.pageSize});

  final int pageSize;
  final List<T> _items = [];
  int _page = -1;
  bool _hasMore = true;
  bool _loading = false;

  List<T> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isLoading => _loading;

  Future<void> reset({
    required Future<List<T>> Function(int page, int limit) load,
  }) async {
    _items.clear();
    _page = -1;
    _hasMore = true;
    await loadMore(load: load);
  }

  Future<void> loadMore({
    required Future<List<T>> Function(int page, int limit) load,
  }) async {
    if (_loading || !_hasMore) return;
    _loading = true;
    try {
      final next = _page + 1;
      final batch = await load(next, pageSize);
      if (batch.length < pageSize) _hasMore = false;
      _items.addAll(batch);
      _page = next;
    } finally {
      _loading = false;
    }
  }

  void prepend(T item) {
    _items.insert(0, item);
  }

  void replace(T item) {
    final i = _items.indexWhere((e) => _idOf(e) == _idOf(item));
    if (i != -1) _items[i] = item;
  }

  void upsert(T item) {
    final i = _items.indexWhere((e) => _idOf(e) == _idOf(item));
    if (i == -1) {
      _items.insert(0, item);
    } else {
      _items[i] = item;
    }
  }

  void removeWhere(bool Function(T) test) {
    _items.removeWhere(test);
  }

  String _idOf(T e) {
    try {
      final dyn = e as dynamic;
      return dyn.id as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
