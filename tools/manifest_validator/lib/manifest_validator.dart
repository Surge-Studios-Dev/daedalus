/// Validates a parsed `surge.manifest.yaml` against the schema rules in
/// `surge.manifest.schema.md`. Returns a list of human-readable errors; empty
/// means valid. Pure: takes an already-parsed [Map] (a `YamlMap` is a `Map`).
///
/// This is the single rule set: the brick's `pre_gen.dart` imports it (path
/// dep), so a bad manifest fails before anything is stamped, and there is no
/// inline mirror to drift.
List<String> validateManifest(Map manifest) {
  final errors = <String>[];

  bool missing(Object? v) =>
      v == null || (v is String && v.trim().isEmpty);
  void req(Map? m, String key, String path) {
    if (m == null || missing(m[key])) errors.add('$path.$key is required');
  }

  // identity
  final identity = manifest['identity'];
  if (identity is! Map) {
    errors.add('identity is required');
  } else {
    req(identity, 'slug', 'identity');
    req(identity, 'name', 'identity');
    req(identity, 'bundle_id_ios', 'identity');
    req(identity, 'package_android', 'identity');
    final slug = identity['slug'];
    if (slug is String && !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(slug)) {
      errors.add('identity.slug "$slug" must be lowercase snake_case (a-z, 0-9, _)');
    }
  }

  // navigation
  final tabs = (manifest['navigation'] as Map?)?['tabs'];
  if (tabs is! List || tabs.isEmpty) {
    errors.add('navigation.tabs is required');
  } else {
    if (tabs.length < 2 || tabs.length > 5) {
      errors.add('navigation.tabs must have 2-5 entries (has ${tabs.length})');
    }
    var builtins = 0;
    for (var i = 0; i < tabs.length; i++) {
      final t = tabs[i];
      final at = 'navigation.tabs[$i]';
      if (t is! Map) {
        errors.add('$at must be a map');
        continue;
      }
      req(t, 'id', at);
      req(t, 'label', at);
      req(t, 'icon', at);
      final type = t['type'];
      if (type != 'feature' && type != 'builtin') {
        errors.add('$at.type must be feature|builtin (got "$type")');
      }
      if (type == 'builtin') builtins++;
    }
    if (builtins == 0) {
      errors.add('navigation.tabs needs at least one builtin tab (the settings/You tab)');
    }
  }

  // auth
  final providers = (manifest['auth'] as Map?)?['providers'];
  if (providers is! List || providers.isEmpty) {
    errors.add('auth.providers must list at least one of email|apple|google');
  } else {
    const allowed = {'email', 'apple', 'google'};
    for (final p in providers) {
      if (!allowed.contains(p)) {
        errors.add('auth.providers has unknown provider "$p"');
      }
    }
  }

  // monetization
  final mon = manifest['monetization'];
  if (mon is! Map) {
    errors.add('monetization is required');
  } else {
    req(mon, 'entitlement', 'monetization');
    final model = mon['model'];
    if (!{'subscription', 'one_time', 'hybrid'}.contains(model)) {
      errors.add('monetization.model must be subscription|one_time|hybrid (got "$model")');
    }
    final trial = mon['trial'] as Map?;
    final trialType = trial?['type'] ?? 'none';
    if (!{'store_intro_offer', 'app_gated', 'none'}.contains(trialType)) {
      errors.add('monetization.trial.type must be store_intro_offer|app_gated|none (got "$trialType")');
    }
    if (model == 'subscription' && trialType == 'app_gated') {
      errors.add('subscription model cannot use trial.type app_gated (use store_intro_offer or none)');
    }
    if (model == 'one_time' && trialType == 'store_intro_offer') {
      errors.add('one_time model cannot use trial.type store_intro_offer (use app_gated or none)');
    }
    final days = trial?['duration_days'];
    if (trialType != 'none' && (days == null || (days is num && days <= 0))) {
      errors.add('monetization.trial.duration_days must be > 0 when trial.type is $trialType');
    }
    final products = mon['products'];
    if (products is! List || products.isEmpty) {
      errors.add('monetization.products must list at least one product');
    } else {
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        final at = 'monetization.products[$i]';
        if (p is! Map) {
          errors.add('$at must be a map');
          continue;
        }
        req(p, 'id', at);
        if (!{'auto_renew_subscription', 'non_consumable'}.contains(p['type'])) {
          errors.add('$at.type must be auto_renew_subscription|non_consumable (got "${p['type']}")');
        }
      }
    }
  }

  // legal
  final legal = manifest['legal'];
  if (legal is! Map) {
    errors.add('legal is required');
  } else {
    req(legal, 'privacy_url', 'legal');
    req(legal, 'terms_url', 'legal');
  }

  // integrations
  final integrations = manifest['integrations'];
  if (integrations is! Map || missing(integrations['firebase_project'])) {
    errors.add('integrations.firebase_project is required');
  }

  return errors;
}
