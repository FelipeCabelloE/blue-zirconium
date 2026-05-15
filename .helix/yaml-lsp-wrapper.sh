#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/recipe-v1.json"
SCHEMA_URL="https://schema.blue-build.org/recipe-v1.json"
MAX_AGE=86400

need_fetch=false
if [ ! -f "$SCHEMA_FILE" ]; then
    need_fetch=true
else
    age=$(($(date +%s) - $(stat -c %Y "$SCHEMA_FILE")))
    [ $age -ge $MAX_AGE ] && need_fetch=true
fi

$need_fetch && curl -sfL -o "$SCHEMA_FILE" "$SCHEMA_URL"

exec yaml-language-server "$@"
