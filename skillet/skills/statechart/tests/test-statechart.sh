#!/usr/bin/env bash
# Offline package contract. TLC integrations report explicit skips without TLA2TOOLS.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js 18 or later is required for statechart tests" >&2
  exit 2
fi
node --test --test-reporter=tap scripts/test/statechart.test.mjs tests/render.test.mjs
