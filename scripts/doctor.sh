#!/bin/bash
# daedalus doctor - checks the environment against every trap that has
# actually cost a Ladle/Daedalus session time. Read-only; prints PASS /
# WARN / FAIL lines and exits non-zero only on FAILs.
#
#   scripts/doctor.sh
set -uo pipefail

fails=0
pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }

# --- core toolchain -------------------------------------------------------
if command -v flutter >/dev/null 2>&1; then
  pass "flutter: $(flutter --version 2>/dev/null | head -1)"
else
  fail "flutter not on PATH"
fi

if command -v dart >/dev/null 2>&1; then
  pass "dart: $(dart --version 2>&1 | head -1)"
else
  fail "dart not on PATH"
fi

if command -v mason >/dev/null 2>&1; then
  pass "mason: $(mason --version 2>/dev/null | head -1)"
else
  warn "mason not installed (needed to stamp apps): dart pub global activate mason_cli, and make sure ~/.pub-cache/bin is on PATH"
fi

# --- iOS side -------------------------------------------------------------
if command -v xcodebuild >/dev/null 2>&1; then
  pass "xcode: $(xcodebuild -version 2>/dev/null | head -1)"
  # A stale/foreign DEVELOPER_DIR breaks builds in confusing ways.
  xcrun simctl list devices available >/dev/null 2>&1 &&
    pass "simctl answers (simulators reachable)" ||
    warn "simctl not answering - open Xcode once / xcode-select the full Xcode, not CommandLineTools"
else
  warn "xcodebuild not found - iOS builds unavailable on this machine"
fi

# --- backend side ---------------------------------------------------------
if command -v node >/dev/null 2>&1; then
  node_major=$(node --version | sed 's/^v//' | cut -d. -f1)
  npm_major=$(npm --version 2>/dev/null | cut -d. -f1)
  pass "node $(node --version) / npm $(npm --version 2>/dev/null)"
  # Ladle scar: npm 11 + node 25 break the firebase predeploy hook; the
  # workaround is temp-emptying "predeploy" in firebase.json before deploy.
  if [ "${node_major:-0}" -ge 25 ] && [ "${npm_major:-0}" -ge 11 ]; then
    warn "node >=25 with npm >=11: firebase deploy predeploy hooks are known-broken (empty the predeploy array in firebase.json as a workaround)"
  fi
else
  warn "node not found - backend work unavailable"
fi

command -v firebase >/dev/null 2>&1 &&
  pass "firebase-tools: $(firebase --version 2>/dev/null)" ||
  warn "firebase-tools not installed (npm i -g firebase-tools)"

# --- gcloud / ADC ---------------------------------------------------------
if command -v gcloud >/dev/null 2>&1; then
  pass "gcloud: $(gcloud --version 2>/dev/null | head -1)"
  # Ladle scar: the local Functions emulator writes to the REAL Firestore
  # project, and ADC without a quota_project 403s quietly mid-session.
  adc="$HOME/.config/gcloud/application_default_credentials.json"
  if [ -f "$adc" ]; then
    grep -q 'quota_project_id' "$adc" &&
      pass "ADC present with quota_project_id" ||
      warn "ADC has no quota_project_id - emulator/API calls may 403 (gcloud auth application-default set-quota-project <project>)"
  else
    warn "no application-default credentials (gcloud auth application-default login) - needed for local emulator work"
  fi
else
  warn "gcloud not found - provisioning + emulator ADC checks unavailable"
fi

# --- reminders that save real hours (not checkable) ------------------------
cat <<'EOF'
----
Not machine-checkable, but each has cost an afternoon before:
  - v2 callables: firebase-tools does NOT apply invoker:"public"; run the
    gcloud run add-invoker binding once per function (see AI-RAIL/ROADMAP).
  - App Check enforcement 401s app extensions that don't embed Firebase
    (share extensions) - keep it monitor-only until that's solved.
  - The local Functions emulator writes to the REAL Firestore project.
EOF

[ "$fails" -eq 0 ] && echo "doctor: OK" || echo "doctor: $fails FAIL(s)"
exit "$fails"
