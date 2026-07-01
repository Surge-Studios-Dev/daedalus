import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';

/// Whether the user has completed (or skipped) first-run onboarding, persisted
/// via [KeyValueStore] so it only ever shows once (in-memory in tests,
/// shared_preferences in the app). The router reads this to gate /onboarding.
class OnboardingController extends Notifier<bool> {
  static const _key = 'onboarding_complete';

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  bool build() => _store.getBool(_key) ?? false;

  void markSeen() {
    state = true;
    _store.setBool(_key, true);
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
