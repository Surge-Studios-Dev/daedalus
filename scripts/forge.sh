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

# ---------- 4. legal drafts ----------
step "4. Legal drafts"
mkdir -p legal
gen_legal() {
  local kind="$1" out="legal/$1.md"
  {
    echo "# ${NAME} - ${kind^} (DRAFT)"
    echo
    echo "Last updated: $(date +%Y-%m-%d). Contact: ${SUPPORT}."
    echo
    echo "> DRAFT generated from surge.manifest.yaml data_practices. This is a"
    echo "> starting point, not legal advice. Have it reviewed before publishing."
    echo
    if [ "$kind" = "privacy" ]; then
      echo "## Data we handle"
      [ "$(m '.legal.data_practices.collects_email')" = "true" ]   && echo "- Account email, to sign you in and contact you about the service."
      [ "$(m '.legal.data_practices.analytics')" = "true" ]        && echo "- Usage analytics (aggregate), to understand and improve the app."
      [ "$(m '.legal.data_practices.crash_reporting')" = "true" ]  && echo "- Crash diagnostics, to find and fix defects."
      [ "$TRACKING" = "true" ]                                      && echo "- Cross-app tracking identifiers (with your permission via the system prompt)."
      echo
      echo "## Your choices"
      echo "- You can delete your account and associated data in-app under Account."
      echo "- You can request export or deletion by emailing ${SUPPORT}."
    else
      echo "## Terms"
      echo "- ${NAME} is provided as-is. Subscriptions and purchases are billed"
      echo "  through the App Store or Google Play and managed there."
      echo "- The current monetization model is: ${MODEL}."
    fi
  } > "$out"
  ok "wrote $out"
}
gen_legal privacy
gen_legal terms

# ---------- 5. secrets ----------
step "5. Secrets"
if [ -n "${REVENUECAT_KEY:-}" ]; then
  ok "REVENUECAT_KEY present in environment"
else
  note "REVENUECAT_KEY not set. Add it to CI / a gitignored .env; never commit it."
fi

# ---------- 6. manual checklist ----------
step "Manual checklist (needs a browser)"
bold "App Store Connect + Play Console"
echo "  - Create app records for $IOS_ID and $AND_ID."
echo "  - Set support URL and the privacy policy URL ($(m '.legal.privacy_url'))."
echo
bold "RevenueCat"
echo "  - Create the app, an entitlement '$ENTITLEMENT', and these products:"
yq -r '.monetization.products[] | "      - " + .id + " (" + .type + ", ref " + (.reference_price|tostring) + ")"' "$MANIFEST"
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
bold "Before submission"
echo "  - Replace every lib/features/* stub with real functionality (stub-only fails Apple 4.3)."
echo "  - Verify in-app account deletion, restore purchases, and Sign in with Apple all work."
[ "$TRACKING" = "true" ] && echo "  - Confirm the ATT prompt fires and the Info.plist usage string is set."
echo
ok "init complete for $NAME"
