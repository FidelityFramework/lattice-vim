#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
exec nvim --headless -u NONE -i NONE -l tests/headless.lua
