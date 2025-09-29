#!/usr/bin/env bash
set -euo pipefail

# Runs Firebase emulators and the MCP server (inside functions/) for local development.
# Prereqs: Node 20+, Firebase CLI, functions/ TypeScript build scripts.

pushd "$(dirname "$0")/.." >/dev/null

echo "[MCP] Installing function deps..."
npm --prefix functions ci

echo "[MCP] Building functions (TypeScript -> JS)..."
npm --prefix functions run build

echo "[MCP] Starting Firebase emulators (Firestore/Auth/Functions)..."
# If you have an npm script for emulator, prefer it; otherwise call Firebase CLI directly.
if npm --prefix functions run | grep -q "serve"; then
  npm --prefix functions run serve
else
  firebase emulators:start --only firestore,functions,auth
fi

popd >/dev/null

