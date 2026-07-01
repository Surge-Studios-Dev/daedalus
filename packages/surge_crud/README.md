# surge_crud

Generic collection data plumbing — a **Tier 3 System** (see
[`../../FRAMEWORK.md`](../../FRAMEWORK.md)). A feature depends on a
`CrudRepository<T>` and gets list/read/create/update/delete without re-deriving
Firestore wiring. Same swap pattern as auth and purchases: mock in dev/tests,
Firestore in a configured build.

## Use it

```dart
import 'package:surge_crud/surge_crud.dart';

// dev / tests
final repo = InMemoryCrudRepository<Note>(idOf: (n) => n.id);

// configured build (Firestore-backed, same interface)
final repo = FirestoreCrudRepository<Note>(
  collectionPath: 'notes',
  idOf: (n) => n.id,
  toMap: (n) => {'text': n.text},
  fromMap: (id, data) => Note(id, data['text'] as String),
);

repo.watchAll().listen(render);   // live list
await repo.upsert(Note('1', 'hi'));
await repo.delete('1');
```

Wrap the repository in a Riverpod provider in your app and select the binding in
`bootstrap` (behind the same `useFirebase` flag), exactly like `AuthService` and
`PurchaseService`.

## Why it's a System

It composes a real capability (persistence) behind one interface with a
swappable backend, taking type + converters as parameters instead of reaching
into app state — the standard Tier 3 contract.

## Status

v0.1.0 — interface + in-memory + Firestore implementations. In-memory path
covered by tests (seed/upsert/fetch/delete + the watch stream). The Firestore
path compiles against `cloud_firestore`; verify it live against a project.
