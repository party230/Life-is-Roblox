#!/usr/bin/env bash
# CI-style gate: format check, lint, type-check, build, unit tests.
# Usage: scripts/check.sh            (check only)
#        scripts/check.sh --fix      (apply StyLua formatting first)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [[ -d "$ROOT/.tools/bin" ]]; then
	export PATH="$ROOT/.tools/bin:$PATH"
fi

step() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

if [[ "${1:-}" == "--fix" ]]; then
	step "StyLua (format)"
	stylua src tests
else
	step "StyLua (check)"
	stylua --check src tests
fi

step "Selene (lint)"
if [[ ! -f roblox.yml ]]; then
	selene generate-roblox-std
fi
selene src tests

step "Rojo (build)"
mkdir -p build
rojo build default.project.json -o build/RotShift.rbxl
rojo sourcemap default.project.json -o sourcemap.json

step "luau-lsp (strict type-check)"
DEFS="$ROOT/.tools/globalTypes.d.luau"
if [[ ! -f "$DEFS" ]]; then
	echo "Missing $DEFS - run scripts/install-tools.sh" >&2
	exit 1
fi
luau-lsp analyze \
	--platform=roblox \
	--sourcemap=sourcemap.json \
	--definitions=@roblox="$DEFS" \
	--ignore="src/server/Vendor/**" \
	--ignore="Packages/**" \
	--ignore="ServerPackages/**" \
	--ignore="tests/run.luau" \
	src tests

step "Unit tests (Lune)"
lune run tests/run.luau

printf '\n\033[32mAll checks passed.\033[0m\n'
