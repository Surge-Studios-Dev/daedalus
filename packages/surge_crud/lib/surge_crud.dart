/// Surge CRUD — generic collection data plumbing (Tier 3 System).
///
/// Depend on [CrudRepository]; bind [InMemoryCrudRepository] in dev/tests and
/// `FirestoreCrudRepository` in a configured build.
///
/// ```dart
/// final repo = InMemoryCrudRepository<Note>(idOf: (n) => n.id);
/// await repo.upsert(Note(id: '1', text: 'hi'));
/// repo.watchAll().listen(render);
/// ```
library;

export 'src/crud_repository.dart';
export 'src/in_memory_crud_repository.dart';
export 'src/firestore_crud_repository.dart';
