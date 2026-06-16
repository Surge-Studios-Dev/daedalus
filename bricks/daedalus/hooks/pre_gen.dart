import 'dart:io';
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

/// Reads surge.manifest.yaml and flattens it into Mason vars, so a single
/// `mason make daedalus` produces a fully configured app. The manifest is the
/// only thing a human edits; everything downstream is generated from it.
Future<void> run(HookContext context) async {
  final path = (context.vars['manifest'] as String?) ?? 'surge.manifest.yaml';
  final file = File(path);
  if (!file.existsSync()) {
    context.logger.err('Manifest not found at $path');
    exit(1);
  }
  final m = loadYaml(file.readAsStringSync()) as YamlMap;

  final identity = m['identity'] as YamlMap;
  final brand = (m['brand'] as YamlMap?) ?? YamlMap();
  final palette = (brand['palette'] as YamlMap?) ?? YamlMap();
  final fonts = (brand['fonts'] as YamlMap?) ?? YamlMap();
  final auth = (m['auth'] as YamlMap?) ?? YamlMap();
  final providers =
      (auth['providers'] as YamlList?)?.map((e) => '$e').toList() ?? const <String>[];
  final mon = m['monetization'] as YamlMap;
  final trial = (mon['trial'] as YamlMap?) ?? YamlMap();
  final features = (m['features'] as YamlMap?) ?? YamlMap();
  final nav = (m['navigation'] as YamlMap?) ?? YamlMap();
  final studio = (m['studio'] as YamlMap?) ?? YamlMap();

  String toColor(Object? hex, String fallback) {
    var s = (hex?.toString() ?? fallback).replaceAll('#', '').toUpperCase();
    if (s.length == 6) s = 'FF$s';
    return '0x$s';
  }

  // Apple sign-in is force-included whenever a social provider is present,
  // to satisfy App Store Guideline 4.8.
  final hasSocial = providers.any((p) => p != 'email');

  context.vars = {
    ...context.vars,
    'slug': identity['slug'],
    'name': identity['name'],
    'tagline': identity['tagline'] ?? '',
    'bundle_id_ios': identity['bundle_id_ios'],
    'package_android': identity['package_android'],
    'accent_hex': toColor(palette['accent'], '#75D8FF'),
    'accent_soft_hex': toColor(palette['accent_soft'], '#2B89D8'),
    'panel_hex': toColor(palette['panel'], '#0E1B27'),
    'font_display': fonts['display'] ?? 'Inter',
    'font_text': fonts['text'] ?? 'Inter',
    'auth_email': providers.contains('email'),
    'auth_apple': providers.contains('apple') || hasSocial,
    'auth_google': providers.contains('google'),
    'guest_mode': auth['guest_mode'] ?? false,
    'entitlement': mon['entitlement'] ?? 'pro',
    'mon_model': mon['model'] ?? 'subscription',
    'trial_type': trial['type'] ?? 'none',
    'trial_days': trial['duration_days'] ?? 0,
    'remote_config': features['remote_config'] ?? false,
    'notifications': features['notifications'] ?? false,
    'cross_promo': features['cross_promo'] ?? false,
    'support_email': studio['support_email'] ?? '',
    'tabs': (nav['tabs'] as YamlList?)
            ?.map((t) => {
                  'id': t['id'],
                  'label': t['label'],
                  'icon': t['icon'],
                  'builtin': t['type'] == 'builtin',
                })
            .toList() ??
        const [],
    'gates':
        (mon['gates'] as YamlList?)?.map((e) => {'gate': '$e'}).toList() ?? const [],
  };

  context.logger
      .info('Configured ${identity['name']} (${mon['model']} / ${trial['type']})');
}
