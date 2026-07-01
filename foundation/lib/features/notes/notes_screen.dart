import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import 'notes.dart';

/// NTS-01 · Notes (reference feature). Demonstrates the Tier-3 CRUD contract
/// end to end: SurgeTextField + SurgeListRow over a CrudRepository stream.
/// In-memory by default; per-user Firestore when the bootstrap seam is on.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(notesRepositoryProvider).upsert(
          Note(id: 'n$now', text: text, createdAt: now),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SurgeTextField(
                    controller: _controller,
                    placeholder: 'Write a note…',
                    onSubmitted: (_) => _add(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: SurgeSpace.sm),
                SurgeIconButton(
                  icon: Icons.add,
                  semanticLabel: 'Add note',
                  onPressed: _add,
                ),
              ],
            ),
          ),
          Expanded(
            child: notes.when(
              loading: () => const Center(child: SurgeSpinner()),
              error: (e, _) => Center(
                child: Text('$e', style: SurgeText.footnote),
              ),
              data: (items) => items.isEmpty
                  ? const SurgeEmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'No notes yet',
                      sub: 'Notes prove the CRUD seam: in-memory here, '
                          'per-user Firestore once the seam is flipped.',
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final n = items[i];
                        return SurgeListRow(
                          title: n.text,
                          icon: Icons.sticky_note_2_outlined,
                          trailing: SurgeIconButton(
                            icon: Icons.delete_outline,
                            semanticLabel: 'Delete note',
                            onPressed: () => ref
                                .read(notesRepositoryProvider)
                                .delete(n.id),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
