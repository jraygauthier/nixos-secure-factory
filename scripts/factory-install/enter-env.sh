#!/usr/bin/env bash
set -euf -o pipefail
script_dir="$(cd "$(dirname $0)" > /dev/null;pwd)"
factory_install_repo_root_dir="$(cd "$(dirname $0)/../.." > /dev/null;pwd)"
# Should help with developping scripts.
export PKG_NIXOS_FACTORY_COMMON_INSTALL_FACTORY_STATE_REPO_DIR="$factory_install_repo_root_dir"
# TODO: Move out of the factory install directory.
device_cfg_repo_root_dir="$(cd "$(dirname $0)/../../demo-nixos-config" > /dev/null;pwd)"
# device_cfg_repo_root_dir="$factory_install_repo_root_dir"
export PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR="$device_cfg_repo_root_dir"

# Should help with developping scripts.
scripts_dir="$factory_install_repo_root_dir/scripts"
export PKG_NIXOS_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common-install"
export PKG_NIXOS_DEVICE_SYSTEM_CONFIG_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/device-system-config"
export PKG_NIXOS_FACTORY_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/factory-common-install"
export PKG_NIXOS_FACTORY_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/factory-install"

# TODO: Check that proper sshd version is installed.
# TODO: Check that proper VBox version is installed.

# nix-shell $script_dir/env.nix "$@"

nix-shell -p "import $script_dir/env.nix {}" "$@"