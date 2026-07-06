#!/bin/bash
# The merge bar (CLAUDE.md): analyze clean + formatted + tests green before
# any commit. Fired as a PreToolUse hook on Bash calls; ignores everything
# that isn't a git commit. Exit 2 blocks the commit and feeds the failure
# back to the agent - self-reports don't count, this does.
input=$(cat)
printf '%s' "$input" | grep -q 'git commit' || exit 0

cd "$CLAUDE_PROJECT_DIR" || exit 0

fail() {
  printf 'Merge bar blocked the commit.\n%s\n' "$1" >&2
  exit 2
}

analyze=$(flutter analyze 2>&1) ||
  fail "flutter analyze is not clean:
$(printf '%s' "$analyze" | tail -20)"

dart format --output=none --set-exit-if-changed lib test >/dev/null 2>&1 ||
  fail "dart format found unformatted files. Run: dart format lib test"

tests=$(flutter test 2>&1) ||
  fail "flutter test failed:
$(printf '%s' "$tests" | tail -30)"

exit 0
