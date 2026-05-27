#!/bin/sh
# tests/run.sh — minimal runner for aria-ex1 hook repros.
# Executes every *.sh under tests/repros/ and aggregates pass/fail.

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=""

for suite in repros/*.sh; do
  printf "=== %s ===\n" "$suite"
  if sh "$suite"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_SUITES="$FAILED_SUITES $suite"
  fi
  printf "\n"
done

printf "=== workspace index (python) ===\n"
if command -v python3 >/dev/null 2>&1; then
  if python3 "$SCRIPT_DIR/test_workspace_index.py"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_SUITES="$FAILED_SUITES tests/test_workspace_index.py"
  fi
else
  printf "SKIP: python3 not on PATH\n"
fi
printf "\n"

printf "=== SUMMARY ===\n"
printf "%d suite(s) passed, %d suite(s) failed\n" "$TOTAL_PASS" "$TOTAL_FAIL"
if [ -n "$FAILED_SUITES" ]; then
  printf "Failed:%s\n" "$FAILED_SUITES"
  exit 1
fi
exit 0
