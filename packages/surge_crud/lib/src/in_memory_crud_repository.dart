import 'dart:async';

import 'crud_repository.dart';

/// In-memory [CrudRepository] for development and tests. Holds items in a map
/// keyed by id and emits the full list on every mutation.
class InMemoryCrudRepository<T> implements CrudRepository<T> {
  InMemoryCrudRepository({required this.idOf, List<T> seed = const []}) {
    for (final item in seed) {
      _items[idOf(item)] = item;
    }
  }

  /// Extracts the id from an item (used by [upsert]).
  final String Function(T item) idOf;

  final _items = <String, T>{};
  final _controller = StreamController<List<T>>.broadcast();

  List<T> get _snapshot => List.unmodifiable(_items.values);
  void _emit() => _controller.add(_snapshot);

  @override
  Stream<List<T>> watchAll() async* {
    yield _snapshot; // current state first
    yield* _controller.stream; // then every change
  }

  @override
  Future<List<T>> fetchAll() async => _snapshot;

  @override
  Future<T?> fetch(String id) async => _items[id];

  @override
  Future<void> upsert(T item) async {
    _items[idOf(item)] = item;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _emit();
  }

  void dispose() => _controller.close();
}
