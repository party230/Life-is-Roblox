#!/usr/bin/env bash
# Downloads the pinned toolchain into .tools/bin (used by CI and by machines without Rokit).
# Versions must match rokit.toml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.tools/bin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN"

fetch() {
	local name="$1" url="$2"
	if [[ -x "$BIN/$name" ]]; then
		return
	fi
	echo "Installing $name"
	curl -fsSL --retry 4 -o "$TMP/$name.zip" "$url"
	unzip -o -q "$TMP/$name.zip" -d "$TMP/$name"
	find "$TMP/$name" -type f -name "$name" -exec cp {} "$BIN/$name" \;
	chmod +x "$BIN/$name"
}

GH="https://github.com"
fetch rojo "$GH/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip"
fetch selene "$GH/Kampfkarren/selene/releases/download/0.28.0/selene-0.28.0-linux.zip"
fetch stylua "$GH/JohnnyMorganz/StyLua/releases/download/v2.0.2/stylua-linux-x86_64.zip"
fetch lune "$GH/lune-org/lune/releases/download/v0.10.4/lune-0.10.4-linux-x86_64.zip"
fetch luau-lsp "$GH/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip"
fetch wally "$GH/UpliftGames/wally/releases/download/v0.3.2/wally-v0.3.2-linux.zip"

# Roblox API type definitions for luau-lsp.
if [[ ! -f "$ROOT/.tools/globalTypes.d.luau" ]]; then
	curl -fsSL --retry 4 -o "$ROOT/.tools/globalTypes.d.luau" \
		"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau"
fi
echo "Tools ready in $BIN"
