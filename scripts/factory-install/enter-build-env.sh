#!/usr/bin/env bash
set -euf -o pipefail
script_dir="$(cd "$(dirname "$0")" > /dev/null && pwd)"

NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR="$script_dir"
. "$NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR/env.sh"
unset NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR

export PKG_NIXOS_SF_FACTORY_INSTALL_IN_BUILD_ENV=1
nix-shell "$script_dir/release.nix" "$@"
