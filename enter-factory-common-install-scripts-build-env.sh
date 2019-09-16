#!/usr/bin/env bash
set -euf -o pipefail
script_dir="$(cd "$(dirname "$0")" > /dev/null && pwd)"
"$script_dir/scripts/factory-common-install/enter-build-env.sh" "$@"
