/// A generic collection repository the app depends on instead of Firestore
/// directly, so data plumbing is a swappable implementation:
/// [InMemoryCrudRepository] for dev/tests, `FirestoreCrudRepository` in a
/// configured build. One instance owns one collection of [T].
abstract interface class CrudRepository<T> {
  /// Live list of all items; emits on every change.
  Stream<List<T>> watchAll();

  /// One-shot read of all items.
  Future<List<T>> fetchAll();

  /// Read a single item by id, or null if absent.
  Future<T?> fetch(String id);

  /// Create or replace [item] (id derived via the repository's id function).
  Future<void> upsert(T item);

  /// Delete the item with [id].
  Future<void> delete(String id);
}
