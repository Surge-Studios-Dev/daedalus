#!/usr/bin/env bash
#
# forge.sh - provision a freshly stamped Surge app so it can ship.
#
# Run from the app repo root (the directory containing surge.manifest.yaml and
# the generated Flutter project). It reads the manifest and performs the
# automatable setup, then prints the manual checklist that needs a human + a
# browser. Safe to re-run; steps are idempotent or skip when already done.
#
# Dependency: yq (https://github.com/mikefarah/yq). Everything else (flutter,
# dart, flutterfire) is assumed present in a Flutter shop.
#
# This script shells out to real CLIs; sanity-check the exact flag spellings
# against your installed flutterfire_cli / rename versions the first time.

set -euo pipefail

MANIFEST="${1:-surge.manifest.yaml}"

# ---------- output helpers ----------
bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; }
note() { printf '  \033[33mnote\033[0m %s\n' "$1"; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

# Run a command, but on failure print a manual note instead of aborting the
# whole script. Provisioning is partly manual anyway; one missing tool should
# not block the rest.
soft() {
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else note "could not auto-run: $desc (do it manually)"; fi
}

# ---------- preflight ----------
step "Preflight"
[ -f "$MANIFEST" ] || { echo "Manifest not found: $MANIFEST"; exit 1; }
command -v yq >/dev/null      || { echo "yq is required. Install: brew install yq"; exit 1; }
command -v flutter >/dev/null || { echo "flutter is required."; exit 1; }
command -v dart >/dev/null    || { echo "dart is required."; exit 1; }
command -v flutterfire >/dev/null || note "flutterfire CLI missing (dart pub global activate flutterfire_cli)"
ok "manifest: $MANIFEST"

# ---------- read manifest ----------
m() { yq -r "$1" "$MANIFEST"; }
SLUG=$(m '.identity.slug')
NAME=$(m '.identity.name')
IOS_ID=$(m '.identity.bundle_id_ios')
AND_ID=$(m '.identity.package_android')
FB_PROJECT=$(m '.integrations.firebase_project')
SUPPORT=$(m '.studio.support_email')
MODEL=$(m '.monetization.model')
ENTITLEMENT=$(m '.monetization.entitlement')
TRIAL_TYPE=$(m '.monetization.trial.type')
TRIAL_DAYS=$(m '.monetization.trial.duration_days')
TRACKING=$(m '.legal.data_practices.tracking')
ok "$NAME ($SLUG) - $MODEL / $TRIAL_TYPE ${TRIAL_DAYS}d"

# ---------- 0. packages + platform folders ----------
# The app depends on the shared surge_ui / surge_onboarding / surge_crud packages
# (default: siblings of Daedalus in the workspace). A lean stamp ships lib/ only,
# so add the native android/ios folders before any build. No codegen step: the
# base uses Riverpod without build_runner.
step "0. Packages + platform folders"
soft "flutter pub get" flutter pub get
if [ -d android ] && [ -d ios ]; then
  ok "android/ios present"
else
  soft "scaffold platform folders" flutter create --platforms=ios,android .
fi

# ---------- 1. identifiers ----------
step "1. Bundle id / package name"
if command -v rename >/dev/null || dart pub global list 2>/dev/null | grep -q '^rename '; then
  soft "set iOS bundle id $IOS_ID"     dart pub global run rename setBundleId --targets ios --value "$IOS_ID"
  soft "set Android package $AND_ID"   dart pub global run rename setBundleId --targets android --value "$AND_ID"
  soft "set app name $NAME"            dart pub global run rename setAppName --targets ios,android --value "$NAME"
else
  note "install the 'rename' tool: dart pub global activate rename"
  note "then set iOS=$IOS_ID Android=$AND_ID name=\"$NAME\""
fi

# ---------- 2. Firebase ----------
step "2. Firebase (flutterfire configure)"
if command -v flutterfire >/dev/null; then
  soft "configure firebase project $FB_PROJECT" \
    flutterfire configure \
      --project="$FB_PROJECT" \
      --platforms=ios,android \
      --ios-bundle-id="$IOS_ID" \
      --android-package-name="$AND_ID" \
      --yes
else
  note "run: flutterfire configure --project=$FB_PROJECT --ios-bundle-id=$IOS_ID --android-package-name=$AND_ID"
fi

# ---------- 3. icons + splash ----------
step "3. Launcher icon + splash"
soft "generate launcher icons"  dart run flutter_launcher_icons
soft "generate splash"          dart run flutter_native_splash:create
note "both read config from pubspec.yaml; point them at assets/brand/ before running for real"

# ---------- 4. legal + compliance ----------
# Generates Privacy Policy + Terms of Service (markdown + legal.json), the Apple
# privacy manifest (PrivacyInfo.xcprivacy), and the store privacy-label
# checklist from data_practices, via tools/legal_gen. Drafts to review, not
# legal advice.
step "4. Legal + compliance"
mkdir -p legal
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LEGAL_TOOL="$SCRIPT_DIR/../tools/legal_gen"
MANIFEST_ABS="$(cd "$(dirname "$MANIFEST")" && pwd)/$(basename "$MANIFEST")"
LEGAL_OUT="$(pwd)/legal"
if command -v dart >/dev/null && [ -d "$LEGAL_TOOL" ]; then
  ( cd "$LEGAL_TOOL" && dart pub get >/dev/null 2>&1 \
      && dart run bin/legal_gen.dart "$MANIFEST_ABS" "$LEGAL_OUT" ) \
    && ok "wrote legal/{privacy.md,terms.md,legal.json,PrivacyInfo.xcprivacy,store-privacy-labels.md}" \
    || note "legal_gen failed; run it manually from $LEGAL_TOOL"
  # Apple wants the privacy manifest inside the iOS Runner.
  if [ -d ios/Runner ] && [ -f legal/PrivacyInfo.xcprivacy ]; then
    cp legal/PrivacyInfo.xcprivacy ios/Runner/PrivacyInfo.xcprivacy
    ok "copied PrivacyInfo.xcprivacy into ios/Runner (add it to the Xcode target)"
  fi
  note "register on the marketing site: copy legal/legal.json -> Surge-Studios-Site/src/content/legal/$SLUG.json, then 'npm run build:legal'. It appears at /$SLUG/privacy, /$SLUG/terms and on the master policy's covered-products list."
  note "add to the portfolio: 'dart run portfolio_gen $MANIFEST_ABS' from tools/portfolio_gen, paste the entry into Surge-Studios-Site/src/content/portfolio.ts, then fill the TODO narrative."
else
  note "dart or tools/legal_gen missing; generate legal assets manually"
fi

# ---------- 4a. store metadata ----------
# Fastlane deliver/supply trees generated from the manifest store block.
# Regenerate whenever store copy changes in the manifest.
step "4a. Store metadata (fastlane/metadata)"
STORE_TOOL="$SCRIPT_DIR/../tools/store_gen"
APP_ROOT="$(pwd)"
if [ -d "$STORE_TOOL" ]; then
  ( cd "$STORE_TOOL" && dart pub get >/dev/null 2>&1 \
      && dart run bin/store_gen.dart "$MANIFEST_ABS" "$APP_ROOT" ) \
    && ok "wrote fastlane/metadata (deliver + supply)" \
    || note "store_gen failed; run it manually from $STORE_TOOL"
else
  note "tools/store_gen missing; write fastlane/metadata by hand"
fi

# ---------- 4b. backend (rules + functions) ----------
# The stamp ships firestore.rules (deny-by-default, per-user isolation),
# firestore.indexes.json, and backend/ (Functions: account-deletion purge +
# callable pattern; rules unit tests). Deploy rules BEFORE flipping
# useFirebase, or first writes fail against the default locked project.
step "4b. Backend (rules + functions)"
if [ -d backend ]; then
  soft "npm install (backend)" bash -c 'cd backend && npm install --no-audit --no-fund'
  note "rules tests: (cd backend && npm test) - needs Java for the Firestore emulator"
  note "deploy rules + indexes: firebase deploy --only firestore"
  note "deploy functions (account-deletion data purge): firebase deploy --only functions"
else
  note "no backend/ directory (older stamp) - restamp or copy the backend template"
fi

# ---------- 5. secrets ----------
step "5. Secrets"
if [ -n "${REVENUECAT_KEY:-}" ]; then
  ok "REVENUECAT_KEY present in environment"
else
  note "REVENUECAT_KEY not set. Add it to CI / a gitignored .env; never commit it."
fi

# ---------- 6. manual checklist ----------
step "Manual checklist (mostly automatable: scripts/provision.sh)"
note "scripts/provision.sh executes most of the below from provision.env credentials; run it with --dry-run first to review the plan. What follows is the fallback / verification list."
bold "App Store Connect + Play Console"
echo "  - Create app records for $IOS_ID and $AND_ID."
echo "  - Set support URL and the privacy policy URL ($(m '.legal.privacy_url'))."
echo
bold "RevenueCat"
echo "  - Create the app, an entitlement '$ENTITLEMENT', and these products:"
yq -r '.monetization.products[] | "      - " + .id + " (" + .type + ", ref " + (.reference_price|tostring) + ")"' "$MANIFEST"
echo "  - Then set useRevenueCat=true in lib/app/bootstrap.dart and pass the key:"
echo "      flutter run --dart-define=REVENUECAT_KEY=<public sdk key>"
if [ "$MODEL" = "subscription" ] || [ "$MODEL" = "hybrid" ]; then
  echo "  - Configure a ${TRIAL_DAYS}-day introductory free trial on the subscription products."
fi
if [ "$TRIAL_TYPE" = "app_gated" ]; then
  echo "  - One-time model: no store trial. The ${TRIAL_DAYS}-day window is enforced in-app and"
  echo "    tunable via the Remote Config key 'trial_days'."
fi
echo
bold "Signing"
echo "  - iOS: set up Fastlane match or Codemagic signing."
echo "  - Android: generate the upload keystore and wire it into the release build."
echo
bold "Release lanes (fastlane/ is stamped; metadata comes from the manifest)"
echo "  - bundle install                       # once; installs fastlane"
echo "  - bundle exec fastlane ios beta        # TestFlight"
echo "  - bundle exec fastlane android beta    # Play internal track"
echo "  - bundle exec fastlane ios release     # upload + metadata (review manually first)"
echo "  - store copy changed? edit the manifest, re-run tools/store_gen."
echo
bold "Flip the seams to live (they ship as working mocks)"
echo "  - FIRST deploy the backend: firebase deploy --only firestore,functions"
echo "    (rules are deny-by-default; functions include the account-deletion purge)."
echo "  - Auth: after flutterfire configure, set useFirebase=true in lib/app/bootstrap.dart"
echo "    and enable Email/Password (and Apple/Google) in the Firebase console."
echo "  - Purchases: set useRevenueCat=true (see the RevenueCat step above)."
echo
bold "Before submission"
echo "  - Replace every lib/features/* stub with real functionality (stub-only fails Apple 4.3)."
echo "  - Verify in-app account deletion, restore purchases, and Sign in with Apple all work."
[ "$TRACKING" = "true" ] && echo "  - Confirm the ATT prompt fires and the Info.plist usage string is set."
echo

# ---------- 7. ship check ----------
# The pre-submission linter. Red on day 0 is expected - it IS the to-do list.
# Re-run before submitting; add --run-tests for the full gate.
step "7. Ship check (red items = the remaining to-do list)"
SHIP_TOOL="$SCRIPT_DIR/../tools/ship_check"
if [ -d "$SHIP_TOOL" ]; then
  ( cd "$SHIP_TOOL" && dart pub get >/dev/null 2>&1 \
      && dart run bin/ship_check.dart "$APP_ROOT" --manifest="$MANIFEST_ABS" ) \
    || note "re-run before submitting: dart run bin/ship_check.dart . --run-tests (from $SHIP_TOOL)"
else
  note "tools/ship_check missing"
fi

echo
ok "init complete for $NAME"
