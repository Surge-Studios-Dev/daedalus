/// Enforces the foundation <-> brick sync contract (ROADMAP debt D1).
///
/// The brick's `__brick__/lib` is a hand-maintained mirror of `foundation/lib`
/// plus a small, deliberate set of mustache-templated files. This script makes
/// that contract executable so divergence fails CI instead of rotting quietly:
///
///   1. Every foundation/lib file exists in __brick__/lib with identical
///      content (line endings ignored) - unless allowlisted below.
///   2. DIVERGENT files must exist on both sides, must differ, and the brick
///      copy must contain its expected signature (a mustache tag, or the
///      generated-nav import for the forked router/shell). A byte-identical
///      "divergent" file means someone clobbered it with a plain copy.
///   3. FOUNDATION_ONLY files must not exist in the brick (post_gen generates
///      their replacements per app).
///   4. No unexplained brick-only files under lib/.
///   5. ROOT_PARITY files (analysis_options.yaml) match exactly, so stamped
///      apps analyze under the same lints as the foundation.
///
/// Run from the Daedalus repo root (or anywhere - paths resolve from this
/// script's location):  dart scripts/check_brick_sync.dart
library;

import 'dart:io';

/// lib-relative paths that deliberately diverge in the brick, mapped to a
/// signature the brick copy must contain — proof the divergence is still the
/// intended one. Four are mustache-templated; router and tab_shell are forked
/// to read the post_gen-generated nav_config instead of hardcoded tabs.
/// Adding a file here is an architectural decision: it means one more file
/// that must be edited twice. Keep this list short.
const divergent = {
  'app/app.dart': '{{',
  'app/bootstrap.dart': '{{',
  'app/router.dart': 'nav_config.dart',
  'app/theme.dart': '{{',
  'modules/auth/sign_in_screen.dart': '{{',
  'modules/paywall/paywall_screen.dart': '{{',
  'modules/shell/tab_shell.dart': 'nav_config.dart',
};

/// lib-relative paths that exist only in the foundation. Entries ending in
/// '/' are directory prefixes. `features/home` is replaced per app by
/// post_gen's generated stubs; `features/notes/` is the CRUD reference
/// feature (a living example, not something every app ships).
const foundationOnly = {
  'features/home/home_screen.dart',
  'features/notes/',
};

/// Repo-root-relative pairs that must match byte-for-byte.
const rootParity = {
  'foundation/analysis_options.yaml':
      'bricks/daedalus/__brick__/analysis_options.yaml',
};

void main() {
  // scripts/check_brick_sync.dart -> repo root is the script's parent's parent.
  final root = File(Platform.script.toFilePath()).parent.parent.path;
  final fLib = Directory('$root/foundation/lib');
  final bLib = Directory('$root/bricks/daedalus/__brick__/lib');
  final errors = <String>[];

  String norm(String p) => p.replaceAll('\\', '/');
  String read(File f) => f.readAsStringSync().replaceAll('\r\n', '\n');

  Set<String> filesUnder(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => norm(f.path).substring(norm(dir.path).length + 1))
      .toSet();

  final fFiles = filesUnder(fLib);
  final bFiles = filesUnder(bLib);

  bool isFoundationOnly(String rel) => foundationOnly.any(
        (e) => e.endsWith('/') ? rel.startsWith(e) : rel == e,
      );

  // 1 + 2: walk the foundation, compare against the brick.
  for (final rel in fFiles.toList()..sort()) {
    final inBrick = bFiles.contains(rel);
    if (isFoundationOnly(rel)) {
      if (inBrick) {
        errors.add('$rel is FOUNDATION_ONLY but exists in the brick '
            '(the brick must not ship it - delete the brick copy)');
      }
      continue;
    }
    if (!inBrick) {
      errors.add('$rel exists in foundation/lib but not in __brick__/lib '
          '(copy it over, or allowlist it)');
      continue;
    }
    final f = read(File('${fLib.path}/$rel'));
    final b = read(File('${bLib.path}/$rel'));
    final signature = divergent[rel];
    if (signature != null) {
      if (f == b) {
        errors.add('$rel is DIVERGENT but byte-identical to the foundation '
            '(the templated/forked copy was probably clobbered by a plain '
            'copy)');
      } else if (!b.contains(signature)) {
        errors.add('$rel is DIVERGENT but its brick copy lacks the expected '
            'signature "$signature" - re-sync it');
      }
    } else if (f != b) {
      errors.add('$rel differs between foundation/lib and __brick__/lib '
          '(mirror the foundation edit into the brick, or add it to the '
          'divergent allowlist in scripts/check_brick_sync.dart)');
    }
  }

  // 3 (stale allowlist) + 4 (unexplained brick-only files).
  for (final rel in divergent.keys) {
    if (!fFiles.contains(rel)) {
      errors.add('divergent allowlist entry $rel is missing from '
          'foundation/lib (stale allowlist?)');
    }
    if (!bFiles.contains(rel)) {
      errors.add('divergent allowlist entry $rel is missing from '
          '__brick__/lib (stale allowlist?)');
    }
  }
  for (final rel in foundationOnly) {
    final present = rel.endsWith('/')
        ? fFiles.any((f) => f.startsWith(rel))
        : fFiles.contains(rel);
    if (!present) {
      errors.add('FOUNDATION_ONLY entry $rel is missing from foundation/lib '
          '(stale allowlist?)');
    }
  }
  for (final rel in bFiles.difference(fFiles).toList()..sort()) {
    errors.add('$rel exists only in __brick__/lib '
        '(add it to the foundation too, or allowlist it)');
  }

  // 5: root-level parity files.
  rootParity.forEach((a, b) {
    final fa = File('$root/$a');
    final fb = File('$root/$b');
    if (!fa.existsSync() || !fb.existsSync()) {
      errors.add('root parity pair missing: $a <-> $b');
    } else if (read(fa) != read(fb)) {
      errors.add('$a and $b differ (keep them identical)');
    }
  });

  if (errors.isEmpty) {
    final fOnlyCount = fFiles.where(isFoundationOnly).length;
    final mirrored = fFiles.length - fOnlyCount - divergent.length;
    stdout.writeln('brick sync OK: $mirrored mirrored, '
        '${divergent.length} divergent (templated/forked), '
        '$fOnlyCount foundation-only, root parity clean.');
    return;
  }
  stderr.writeln('brick sync FAILED (${errors.length}):');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  stderr.writeln('\nContract: foundation/lib is the source of truth; '
      '__brick__/lib mirrors it except the divergent allowlist.');
  exit(1);
}
