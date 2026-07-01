import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_crud/surge_crud.dart';

/// A note. Deliberately tiny - the point of this feature is the plumbing.
class Note {
  const Note({required this.id, required this.text, required this.createdAt});

  final String id;
  final String text;

  /// Milliseconds since epoch, kept primitive so the map converters stay
  /// trivial and Firestore-safe.
  final int createdAt;

  Map<String, dynamic> toMap() => {'text': text, 'createdAt': createdAt};

  static Note fromMap(String id, Map<String, dynamic> data) => Note(
        id: id,
        text: (data['text'] ?? '') as String,
        createdAt: (data['createdAt'] ?? 0) as int,
      );
}

/// The notes data source - the reference Tier-3 integration: the feature
/// depends on [CrudRepository], never on Firestore. Defaults to in-memory
/// (runs everywhere, tests included); bootstrap overrides it with a
/// [FirestoreCrudRepository] at `users/{uid}/notes` when useFirebase is on -
/// exactly the path `firestore.rules` isolates per user.
final notesRepositoryProvider = Provider<CrudRepository<Note>>(
  (ref) => InMemoryCrudRepository<Note>(idOf: (n) => n.id),
);

/// Live note list, newest first.
final notesProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchAll().map((notes) {
    final sorted = [...notes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  });
});
