#!/usr/bin/env bash
set -euf -o pipefail
script_dir="$(cd "$(dirname "$0")" > /dev/null && pwd)"
CURRENT_PACKAGE_ROOT_DIR="$script_dir"
! test -e "$CURRENT_PACKAGE_ROOT_DIR/.local-env.sh" || \
  . "$CURRENT_PACKAGE_ROOT_DIR/.local-env.sh"
unset CURRENT_PACKAGE_ROOT_DIR

export PKG_NIXOS_SF_FACTORY_INSTALL_IN_BUILD_ENV=1
nix-shell "$script_dir/release.nix" "$@"
