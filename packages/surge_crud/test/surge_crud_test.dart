import 'package:flutter_test/flutter_test.dart';
import 'package:surge_crud/surge_crud.dart';

class Note {
  const Note(this.id, this.text);
  final String id;
  final String text;
}

void main() {
  test('seeds, upserts, fetches, and deletes', () async {
    final repo = InMemoryCrudRepository<Note>(
      idOf: (n) => n.id,
      seed: const [Note('1', 'first')],
    );

    expect((await repo.fetchAll()).length, 1);
    expect((await repo.fetch('1'))?.text, 'first');

    await repo.upsert(const Note('2', 'second'));
    expect((await repo.fetchAll()).length, 2);

    await repo.upsert(const Note('1', 'edited')); // replace
    expect((await repo.fetch('1'))?.text, 'edited');
    expect((await repo.fetchAll()).length, 2);

    await repo.delete('1');
    expect(await repo.fetch('1'), isNull);
    expect((await repo.fetchAll()).length, 1);
  });

  test('watchAll emits current state then every change', () async {
    final repo = InMemoryCrudRepository<Note>(idOf: (n) => n.id);
    final counts = <int>[];
    final sub = repo.watchAll().listen((list) => counts.add(list.length));

    await Future<void>.delayed(Duration.zero); // initial (empty) emission
    await repo.upsert(const Note('1', 'a'));
    await repo.upsert(const Note('2', 'b'));
    await repo.delete('1');
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    repo.dispose();
    expect(counts, [0, 1, 2, 1]);
  });
}
