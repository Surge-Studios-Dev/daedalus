#!/usr/bin/env bash
#
# provision.sh - stand up the CLOUD side of a Surge app from its manifest:
# Firebase/GCP project, Firestore, auth providers, rules deploy, App Store
# Connect record + capabilities, Android keystore, and the full RevenueCat
# object graph (apps, entitlement, products, offering, packages).
#
# Run from the app repo root, AFTER scripts/forge.sh (which handles the local
# side: platform folders, ids, icons, legal, store metadata).
#
#   bash ../Daedalus/scripts/provision.sh [manifest] [--dry-run]
#
# --dry-run prints every mutating command/API call it WOULD make, with real
# values, touching nothing. Use it to review the plan (and to test the script
# without accounts).
#
# Credentials come from provision.env files, loaded in order (later wins):
#   $HOME/.surge/provision.env   studio-wide (billing, ASC key, RevenueCat)
#   ./provision.env              per-app overrides (keystore password)
# Copy provision.env.example from the Daedalus repo. NEVER commit these; this
# script adds them to .gitignore automatically.
#
# Every step is idempotent-or-skippable and degrades to a manual note when
# its tool/credential is missing. SKELETON-HONEST: written against the
# documented CLIs and REST APIs, first proven at live validation - expect to
# adjust flag spellings / API shapes on the first real run.
#
# Deps: yq + jq (winget install MikeFarah.yq jqlang.jq), firebase-tools,
# gcloud, fastlane, keytool, curl - each checked per step, not up front.

set -euo pipefail

# ---------- args ----------
MANIFEST="surge.manifest.yaml"
DRY=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --*) echo "unknown flag: $a"; exit 2 ;;
    *) MANIFEST="$a" ;;
  esac
done

# ---------- output helpers (forge.sh house style) ----------
bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; }
note() { printf '  \033[33mnote\033[0m %s\n' "$1"; NOTES=$((NOTES+1)); }
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
NOTES=0

# Execute (soft-fail -> note) or, in dry-run, print the exact command.
run() {
  local desc="$1"; shift
  if [ "$DRY" = 1 ]; then
    printf '  \033[36mDRY\033[0m  %s\n       $ %s\n' "$desc" "$*"
    return 0
  fi
  if "$@"; then ok "$desc"; else note "failed: $desc (finish manually)"; fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- preflight ----------
step "Preflight"
[ -f "$MANIFEST" ] || { echo "Manifest not found: $MANIFEST"; exit 1; }
have yq || { echo "yq is required (winget install MikeFarah.yq)"; exit 1; }
APP_ROOT="$(pwd)"
[ "$DRY" = 1 ] && note "DRY RUN - nothing below is executed"

# Credentials: studio-wide first, per-app overrides second.
for envf in "$HOME/.surge/provision.env" "./provision.env"; do
  if [ -f "$envf" ]; then
    # shellcheck disable=SC1090
    set -a; . "$envf"; set +a
    ok "loaded $envf"
  fi
done

# Keep secrets and signing material out of git, idempotently.
ensure_ignored() {
  touch .gitignore
  grep -qxF "$1" .gitignore || echo "$1" >> .gitignore
}
ensure_ignored "provision.env"
ensure_ignored "android/key.properties"
ensure_ignored "*.jks"
ok ".gitignore covers provision.env / key.properties / *.jks"

# ---------- read manifest ----------
m() { yq -r "$1" "$MANIFEST"; }
SLUG=$(m '.identity.slug')
NAME=$(m '.identity.name')
IOS_ID=$(m '.identity.bundle_id_ios')
AND_ID=$(m '.identity.package_android')
FB_PROJECT=$(m '.integrations.firebase_project')
ENTITLEMENT=$(m '.monetization.entitlement')
MODEL=$(m '.monetization.model')
NOTIFICATIONS=$(m '.features.notifications')
PROVIDERS=$(m '.auth.providers | join(" ")')
ok "$NAME ($SLUG) -> project $FB_PROJECT, entitlement $ENTITLEMENT, auth [$PROVIDERS]"

# ---------- 1. GCP / Firebase project ----------
# Dry-run always prints the full plan, even where a CLI is missing locally.
step "1. Firebase project + services"
if [ "$DRY" = 1 ] || have firebase; then
  have firebase || note "firebase-tools not installed here (npm i -g firebase-tools; then firebase login)"
  run "create Firebase project $FB_PROJECT" \
    firebase projects:create "$FB_PROJECT" --display-name "$NAME"
else
  note "firebase-tools missing (npm i -g firebase-tools; then firebase login)"
fi
if [ "$DRY" = 1 ] || have gcloud; then
  have gcloud || note "gcloud not installed here (cloud.google.com/sdk; then gcloud auth login)"
  run "enable core APIs" \
    gcloud services enable firebase.googleapis.com firestore.googleapis.com \
      cloudfunctions.googleapis.com identitytoolkit.googleapis.com \
      --project "$FB_PROJECT"
  if [ -n "${GCP_BILLING_ACCOUNT:-}" ]; then
    run "link billing (required for Functions)" \
      gcloud billing projects link "$FB_PROJECT" \
        --billing-account "$GCP_BILLING_ACCOUNT"
  else
    note "GCP_BILLING_ACCOUNT unset - link billing manually before deploying Functions"
  fi
  run "create Firestore database (${FIRESTORE_LOCATION:-nam5})" \
    gcloud firestore databases create \
      --location "${FIRESTORE_LOCATION:-nam5}" --project "$FB_PROJECT"
else
  note "gcloud missing - enable APIs, billing, and Firestore in the console"
fi
note "app registration + config files: flutterfire configure (forge step 2) - re-run it after this script the first time"

# ---------- 2. Auth providers (Identity Toolkit admin API) ----------
# Email/password + the social IdPs, straight from auth.providers. Google's
# OAuth client is normally auto-provisioned; if the API rejects the bare
# enable, finish that one in the console. Apple here covers the Firebase
# side; the iOS capability is step 3, and a Services ID is only needed if
# you later add web/Android Apple sign-in.
step "2. Auth providers [$PROVIDERS]"
if [ "$DRY" = 1 ]; then
  for p in $PROVIDERS; do
    case "$p" in
      email) printf '  \033[36mDRY\033[0m  enable email/password\n       $ curl -X PATCH "https://identitytoolkit.googleapis.com/admin/v2/projects/%s/config?updateMask=signIn.email" -d {signIn:{email:{enabled:true,passwordRequired:true}}}\n' "$FB_PROJECT" ;;
      apple|google) printf '  \033[36mDRY\033[0m  enable %s sign-in\n       $ curl -X POST "https://identitytoolkit.googleapis.com/admin/v2/projects/%s/defaultSupportedIdpConfigs?idpId=%s.com" -d {enabled:true}\n' "$p" "$FB_PROJECT" "$p" ;;
    esac
  done
elif have gcloud && have curl; then
  TOKEN=$(gcloud auth print-access-token 2>/dev/null || true)
  if [ -z "$TOKEN" ]; then
    note "no gcloud credentials (gcloud auth login) - enable providers in the console"
  else
    idp() { # $1 method, $2 url-suffix, $3 body, $4 desc
      if curl -sf -X "$1" \
           "https://identitytoolkit.googleapis.com/admin/v2/projects/$FB_PROJECT/$2" \
           -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
           -d "$3" >/dev/null; then ok "$4"; else note "API rejected: $4 (finish in console)"; fi
    }
    for p in $PROVIDERS; do
      case "$p" in
        email) idp PATCH "config?updateMask=signIn.email" \
                 '{"signIn":{"email":{"enabled":true,"passwordRequired":true}}}' \
                 "email/password enabled" ;;
        google) idp POST "defaultSupportedIdpConfigs?idpId=google.com" \
                  '{"enabled":true}' "Google sign-in enabled" ;;
        apple) idp POST "defaultSupportedIdpConfigs?idpId=apple.com" \
                 '{"enabled":true}' "Apple sign-in enabled (Firebase side)" ;;
      esac
    done
  fi
else
  note "gcloud/curl missing - enable providers in the Firebase console"
fi

# ---------- 3. Apple: bundle id + ASC record + capabilities ----------
step "3. App Store Connect (fastlane produce)"
if [ "$DRY" = 1 ] || { have fastlane && { [ -n "${ASC_KEY_PATH:-}" ] || [ -n "${APPLE_ID:-}" ]; }; }; then
  have fastlane || note "fastlane not installed here (gem install fastlane)"
  PRODUCE_AUTH=()
  [ -n "${ASC_KEY_PATH:-}" ] && PRODUCE_AUTH=(--api_key_path "$ASC_KEY_PATH")
  run "register $IOS_ID + create the App Store Connect record" \
    fastlane produce -a "$IOS_ID" --app_name "$NAME" "${PRODUCE_AUTH[@]}"
  SERVICES=(--sign-in-with-apple)
  [ "$NOTIFICATIONS" = "true" ] && SERVICES+=(--push-notification)
  run "enable capabilities on $IOS_ID (${SERVICES[*]})" \
    fastlane produce enable_services -a "$IOS_ID" "${SERVICES[@]}" "${PRODUCE_AUTH[@]}"
  note "verify produce flag spellings against your fastlane version on first run"
  note "signing: 'fastlane match init' once per studio, then match appstore"
else
  note "fastlane or Apple credentials missing (ASC_KEY_PATH / APPLE_ID) - create the app record + Sign in with Apple capability manually"
fi

# ---------- 4. Android: upload keystore + Play ----------
step "4. Android signing + Play"
if [ -f android/upload-keystore.jks ]; then
  ok "android/upload-keystore.jks exists"
elif have keytool && [ -n "${ANDROID_KEYSTORE_PASS:-}" ] && [ -d android ]; then
  if [ "$DRY" = 1 ]; then
    # Never echo the real password, even in a local plan preview.
    printf '  \033[36mDRY\033[0m  generate upload keystore\n       $ keytool -genkeypair -keystore android/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass *** -keypass *** -dname "CN=Surge Studios LLC"\n'
  else
    run "generate upload keystore" \
      keytool -genkeypair -v -keystore android/upload-keystore.jks \
        -alias upload -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass "$ANDROID_KEYSTORE_PASS" -keypass "$ANDROID_KEYSTORE_PASS" \
        -dname "CN=Surge Studios LLC"
  fi
  if [ "$DRY" = 0 ] && [ ! -f android/key.properties ]; then
    printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=upload\nstoreFile=../upload-keystore.jks\n' \
      "$ANDROID_KEYSTORE_PASS" "$ANDROID_KEYSTORE_PASS" > android/key.properties
    ok "wrote android/key.properties (gitignored)"
  fi
  note "wire the signingConfig into android/app/build.gradle (standard Flutter release-signing block)"
else
  note "skipped keystore (needs android/ dir, keytool, ANDROID_KEYSTORE_PASS)"
fi
note "Play Console has NO app-creation API: create '$NAME' ($AND_ID) manually once - everything after that is automated (supply)"

# ---------- 5. RevenueCat (REST API v2) ----------
# Builds the whole object graph from the manifest monetization block:
# project -> apps -> entitlement -> products -> attach -> offering ->
# packages. API shapes match the documented v2 REST API; verify against the
# current reference on first live run.
step "5. RevenueCat ($MODEL / entitlement '$ENTITLEMENT')"
if [ "$DRY" = 0 ] && [ -z "${REVENUECAT_SECRET_KEY:-}" ]; then
  note "REVENUECAT_SECRET_KEY unset - create project/entitlement/products in the dashboard (see forge checklist)"
elif [ "$DRY" = 0 ] && ! have jq; then
  note "jq missing (winget install jqlang.jq) - RevenueCat automation needs it"
else
  RC="https://api.revenuecat.com/v2"
  rc_call() { # $1 method, $2 path, $3 body, $4 desc -> echoes response json
    if [ "$DRY" = 1 ]; then
      printf '  \033[36mDRY\033[0m  %s\n       $ curl -X %s %s%s -d %s\n' "$4" "$1" "$RC" "$2" "$3" >&2
      echo '{"id":"dry_id"}'
      return 0
    fi
    local resp
    if resp=$(curl -sf -X "$1" "$RC$2" \
        -H "Authorization: Bearer $REVENUECAT_SECRET_KEY" \
        -H "Content-Type: application/json" -d "$3"); then
      ok "$4" >&2; echo "$resp"
    else
      note "API rejected: $4" >&2; echo '{}'
    fi
  }
  # Extract .id from an rc_call response. Dry-run needs no jq at all.
  rid() {
    if [ "$DRY" = 1 ]; then cat >/dev/null; echo "dry_id"; else jq -r '.id // "dry_id"'; fi
  }

  if [ -n "${RC_PROJECT_ID:-}" ]; then
    PID="$RC_PROJECT_ID"; ok "using existing RevenueCat project $PID"
  else
    PID=$(rc_call POST /projects "{\"name\":\"$NAME\"}" "create project '$NAME'" | rid)
  fi

  IOS_APP=$(rc_call POST "/projects/$PID/apps" \
    "{\"name\":\"$NAME iOS\",\"type\":\"app_store\",\"app_store\":{\"bundle_id\":\"$IOS_ID\"}}" \
    "register App Store app ($IOS_ID)" | rid)
  AND_APP=$(rc_call POST "/projects/$PID/apps" \
    "{\"name\":\"$NAME Android\",\"type\":\"play_store\",\"play_store\":{\"package_name\":\"$AND_ID\"}}" \
    "register Play app ($AND_ID)" | rid)

  EID=$(rc_call POST "/projects/$PID/entitlements" \
    "{\"lookup_key\":\"$ENTITLEMENT\",\"display_name\":\"$NAME full access\"}" \
    "create entitlement '$ENTITLEMENT'" | rid)

  OID=$(rc_call POST "/projects/$PID/offerings" \
    '{"lookup_key":"default","display_name":"Standard"}' \
    "create offering 'default'" | rid)

  PRODUCT_IDS=()
  N_PRODUCTS=$(m '.monetization.products | length')
  for ((i=0; i<N_PRODUCTS; i++)); do
    P_ID=$(m ".monetization.products[$i].id")
    P_TYPE=$(m ".monetization.products[$i].type")
    P_PERIOD=$(m ".monetization.products[$i].period // \"\"")
    RC_TYPE=$([ "$P_TYPE" = "auto_renew_subscription" ] && echo subscription || echo one_time)
    case "$P_PERIOD" in
      P1Y) PKG_KEY='$rc_annual';  PKG_NAME=Annual ;;
      P1M) PKG_KEY='$rc_monthly'; PKG_NAME=Monthly ;;
      *)   PKG_KEY='$rc_lifetime'; PKG_NAME=Lifetime ;;
    esac
    # One package per product tier; the iOS and Play PRODUCTS both attach to
    # it (products are per-store-app in RevenueCat, packages are not).
    PKGID=$(rc_call POST "/projects/$PID/offerings/$OID/packages" \
      "{\"lookup_key\":\"$PKG_KEY\",\"display_name\":\"$PKG_NAME\"}" \
      "package $PKG_KEY" | rid)
    for APP_PAIR in "$IOS_APP:app_store" "$AND_APP:play_store"; do
      APP_REF="${APP_PAIR%%:*}"
      PRID=$(rc_call POST "/projects/$PID/products" \
        "{\"store_identifier\":\"$P_ID\",\"app_id\":\"$APP_REF\",\"type\":\"$RC_TYPE\",\"display_name\":\"$P_ID\"}" \
        "create product $P_ID (${APP_PAIR##*:})" | rid)
      PRODUCT_IDS+=("$PRID")
      rc_call POST "/projects/$PID/packages/$PKGID/actions/attach_products" \
        "{\"products\":[{\"product_id\":\"$PRID\",\"eligibility_criteria\":\"all\"}]}" \
        "attach $P_ID (${APP_PAIR##*:}) -> $PKG_KEY" >/dev/null
    done
  done

  ATTACH=$(printf '"%s",' "${PRODUCT_IDS[@]}"); ATTACH="[${ATTACH%,}]"
  rc_call POST "/projects/$PID/entitlements/$EID/actions/attach_products" \
    "{\"product_ids\":$ATTACH}" "attach all products -> '$ENTITLEMENT'" >/dev/null

  note "store-side products (App Store Connect / Play) still need creating with matching ids + prices - see fastlane/metadata and the forge checklist"
  note "grab the PUBLIC SDK key from the RevenueCat app settings -> --dart-define=REVENUECAT_KEY="
fi

# ---------- 6. Deploy the backend ----------
step "6. Deploy rules + functions (BEFORE flipping useFirebase)"
if have firebase; then
  run "deploy Firestore rules + indexes" \
    firebase deploy --only firestore --project "$FB_PROJECT"
  run "deploy Functions (needs billing + backend/npm install)" \
    firebase deploy --only functions --project "$FB_PROJECT"
else
  note "firebase-tools missing - deploy rules before the app's first live write"
fi

# ---------- summary ----------
step "Remaining manual (the irreducible core)"
echo "  - Play Console: click 'Create app' for $AND_ID (no API exists)."
echo "  - Both consoles: privacy questionnaires - answers are pre-generated in legal/store-privacy-labels.md."
echo "  - Store products: create IAP/subscriptions matching the manifest ids + reference prices."
echo "  - Screenshots + review notes."
echo "  - Then: flutterfire configure -> useFirebase=true -> useRevenueCat=true -> ship_check."
echo
if [ "$DRY" = 1 ]; then
  bold "Dry run complete - review the plan above, fill provision.env, re-run without --dry-run."
else
  bold "Provisioning pass complete ($NOTES notes above need a human)."
fi
