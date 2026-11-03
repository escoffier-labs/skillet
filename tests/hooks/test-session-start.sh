#!/usr/bin/env bash
# Offline regression: the compatibility hook must remain silent on every platform.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASH_BIN="$(command -v bash)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for mode in bare claude cursor copilot; do
  vars=()
  case "$mode" in
    claude) vars=(CLAUDE_PLUGIN_ROOT=/x) ;;
    cursor) vars=(CURSOR_PLUGIN_ROOT=/x) ;;
    copilot) vars=(CLAUDE_PLUGIN_ROOT=/x COPILOT_CLI=1) ;;
  esac
  for entry in session-start run-hook.cmd; do
    args=()
    [[ "$entry" == run-hook.cmd ]] && args=(session-start)
    env -i PATH= "${vars[@]}" "$BASH_BIN" "$ROOT/skillet/hooks/$entry" "${args[@]}" >"$TMP/out" 2>"$TMP/err"
    [[ ! -s "$TMP/out" && ! -s "$TMP/err" ]] || { echo "[fail] $mode/$entry injected context"; exit 1; }
  done
done
echo "[ok] session-start compatibility hook is silent"
