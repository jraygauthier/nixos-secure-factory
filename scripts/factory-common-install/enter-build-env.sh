#!/usr/bin/env bash
set -euf -o pipefail
script_dir="$(cd "$(dirname "$0")" > /dev/null && pwd)"
nix-shell "$script_dir/shell.nix" "$@"
