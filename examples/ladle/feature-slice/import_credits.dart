import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../share/share_service.dart';
import 'import_meter_state.dart';

/// The full import allowance: the weekly free meter (spec §4.3) plus
/// referral-earned banked imports (SHARING-DESIGN.md §4). Weekly imports
/// spend first; banked imports never expire and only start draining once
/// the week's 5 are gone. Plus users bypass all of this (unlimited).
class ImportCredits {
  const ImportCredits({required this.weeklyLeft, required this.banked});

  final int weeklyLeft;
  final int banked;

  int get totalLeft => weeklyLeft + banked;
  bool get atLimit => totalLeft <= 0;
}

final importCreditsProvider = Provider<ImportCredits>((ref) {
  final meter = ref.watch(importMeterProvider);
  return ImportCredits(
    weeklyLeft: meter.left,
    banked: ref.watch(bankedImportsProvider),
  );
});

/// Charge one import: the weekly meter while it lasts, then a banked
/// import (server-decremented so it can't be forged or double-spent
/// across devices). Falls back to the plain weekly consume when the
/// banked spend races to empty — same end state the meter had before
/// banked imports existed.
Future<void> consumeImportCredit(Ref ref) async {
  final meter = ref.read(importMeterProvider);
  if (meter.left > 0) {
    await ref.read(importMeterProvider.notifier).consume();
    return;
  }
  final banked = ref.read(bankedImportsProvider);
  if (banked > 0) {
    try {
      final spent = await ref.read(shareServiceProvider).consumeBankedImports();
      if (spent) return;
    } catch (_) {
      // Offline/transient: don't block the import the user already earned;
      // the weekly consume below is a clamped no-op at cap.
    }
  }
  await ref.read(importMeterProvider.notifier).consume();
}
