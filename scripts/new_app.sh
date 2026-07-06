#!/bin/bash
# daedalus new - one command from a finished manifest to a running app.
#
#   scripts/new_app.sh path/to/surge.manifest.yaml [output_dir]
#
# Validates the manifest, generates the spec skeleton, stamps the brick into
# a SIBLING of this checkout (the surge_* path deps assume that layout),
# and proves the stamp with the app's own merge bar (analyze + format +
# test) plus the backend build + unit tests. The INTAKE conversation that
# produces the manifest (and drafts spec §6/§8) is the /new-app skill's job;
# this script is the deterministic tail of it.
set -euo pipefail

# dart-activated CLIs (mason) live in ~/.pub-cache/bin, which the invoking
# shell often doesn't have on PATH - Ember's first stamp died halfway on
# "mason: command not found". Shim it and fail early with the fix.
export PATH="$HOME/.pub-cache/bin:$PATH"
command -v mason >/dev/null 2>&1 ||
  { echo "mason not found - run: dart pub global activate mason_cli" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST_ARG="${1:?usage: new_app.sh <surge.manifest.yaml> [output_dir]}"
MANIFEST="$(cd "$(dirname "$MANIFEST_ARG")" && pwd)/$(basename "$MANIFEST_ARG")"
[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }

SLUG=$(grep -E '^[[:space:]]*slug:' "$MANIFEST" | head -1 |
  sed 's/.*slug:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]')
[ -n "$SLUG" ] || { echo "could not read identity.slug from the manifest" >&2; exit 1; }

OUT="${2:-$ROOT/../$SLUG}"
if [ -e "$OUT" ] && [ -n "$(ls -A "$OUT" 2>/dev/null)" ]; then
  echo "output dir exists and is not empty: $OUT" >&2
  exit 1
fi

# A failed stamp must not strand a partial output dir (the rerun then dies
# on the exists-check above). Remove OUT on failure, but only if this run
# created it.
FRESH_OUT=0
[ -e "$OUT" ] || FRESH_OUT=1
cleanup() {
  status=$?
  if [ "$status" -ne 0 ] && [ "$FRESH_OUT" -eq 1 ] && [ -e "$OUT" ]; then
    echo "stamp failed (exit $status) - removing partial output: $OUT" >&2
    rm -rf "$OUT"
  fi
}
trap cleanup EXIT

# Mason mustache-renders EVERYTHING under __brick__, so build detritus
# there is dangerous, not just slow: a locally npm-installed
# backend/node_modules got its minified JS rendered as templates and
# corrupted (Ember's yargs died mid-file). The stamp installs backend
# deps fresh instead - these dirs must never ship in the brick.
for junk in "$ROOT/bricks/daedalus/__brick__/backend/node_modules" \
            "$ROOT/bricks/daedalus/__brick__/backend/lib"; do
  if [ -e "$junk" ]; then
    echo "   removing brick build detritus: ${junk#"$ROOT"/}" >&2
    rm -rf "$junk"
  fi
done

echo "== 1/6 validate manifest"
(cd "$ROOT/tools/manifest_validator" && dart pub get >/dev/null &&
  dart run bin/validate.dart "$MANIFEST")

echo "== 2/6 stamp $SLUG -> $OUT"
mkdir -p "$OUT"
cp "$MANIFEST" "$OUT/surge.manifest.yaml"
# Mason prompts for every declared var when run non-interactively, so feed a
# config with placeholder values; pre_gen overwrites all of them from the
# manifest. Only the surge_* paths and use_git_deps survive as given
# (sibling-workspace defaults).
CONFIG="$OUT/.mason_config.json"
cat > "$CONFIG" <<EOF
{
  "manifest": "$OUT/surge.manifest.yaml",
  "slug": "$SLUG", "name": "$SLUG", "tagline": "",
  "bundle_id_ios": "placeholder", "package_android": "placeholder",
  "accent_hex": "0xFF75D8FF", "accent_soft_hex": "0xFF2B89D8",
  "panel_hex": "0xFF0E1B27", "theme_pack": "canvas",
  "font_display": "Inter", "font_text": "Inter",
  "auth_email": true, "auth_apple": true, "auth_google": true,
  "guest_mode": true, "entitlement": "pro", "mon_model": "subscription",
  "trial_type": "store_intro_offer", "trial_days": 7, "has_trial": true,
  "remote_config": true, "notifications": false, "cross_promo": true,
  "support_email": "", "firebase_project": "",
  "use_git_deps": false,
  "surge_git_url": "https://github.com/Surge-Studios-Dev/Daedalus.git",
  "surge_git_ref": "main",
  "surge_core_path": "../Daedalus/packages/surge_core",
  "surge_ui_path": "../Daedalus/packages/surge_ui",
  "surge_onboarding_path": "../Daedalus/packages/surge_onboarding",
  "surge_rating_path": "../Daedalus/packages/surge_rating",
  "surge_crud_path": "../Daedalus/packages/surge_crud",
  "surge_share_path": "../Daedalus/packages/surge_share",
  "tabs": [], "gates": []
}
EOF
(cd "$ROOT" && mason get >/dev/null &&
  mason make daedalus -o "$OUT" -c "$CONFIG" --on-conflict overwrite)
rm -f "$CONFIG"

echo "== 3/6 spec skeleton"
(cd "$ROOT/tools/spec_gen" && dart pub get >/dev/null &&
  dart run bin/spec_gen.dart "$OUT/surge.manifest.yaml" "$OUT/design/spec.md")
echo "   -> $OUT/design/spec.md (write §6 screens + §8 edge cases before M3)"

echo "== 4/6 backend deps + unit tests"
# node_modules is never shipped in the brick (see the detritus guard) -
# install fresh, compile, and run the pure unit suite. Rules tests need
# the Firestore emulator and stay out of the stamp proof.
(cd "$OUT/backend" && npm install --no-audit --no-fund >/dev/null &&
  npm run build >/dev/null && npm run test:unit)

echo "== 5/6 prove the stamp (the app's own merge bar)"
# Self-heal formatter drift first: the foundation mirror was formatted
# under the SDK that built it, and the stamping machine's SDK may disagree
# (11 files drifted on Ember, and formatting exposed 5 auto-fixable
# lints). The stamp must pass the same bar the app's commit hook enforces,
# or the very first feature commit gets blocked by factory debt.
(cd "$OUT" &&
  dart format lib test >/dev/null &&
  dart fix --apply >/dev/null &&
  dart format lib test >/dev/null &&
  flutter analyze &&
  dart format --output=none --set-exit-if-changed lib test &&
  flutter test)

echo "== 6/6 done"
cat <<EOF

$SLUG is stamped, analyzed, formatted, and green (app + backend) at:
  $OUT

Next:
  1. Write design/spec.md §6 (screens) + §8 (edge cases); get them approved.
  2. cd $OUT && flutter run          # see the pattern screens
  3. Read .daedalus/state.yaml + MILESTONES.md and start M0.
  4. scripts/forge.sh when heading for the stores.
EOF
