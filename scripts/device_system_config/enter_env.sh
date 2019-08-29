#!/usr/bin/env bash
set -euf -o pipefail
script_dir="$(cd "$(dirname "$0")" > /dev/null;pwd)"
nix-shell -p "import $script_dir/env.nix {}" "$@"