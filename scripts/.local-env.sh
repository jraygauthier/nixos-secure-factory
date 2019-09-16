#!/usr/bin/env bash

# Meant to be sourced.
# Depends on 'CURRENT_REPOSITORY_SCRIPTS_DIR' being set to this script's dir.

project_top_level_root_dir="$(cd "$CURRENT_REPOSITORY_SCRIPTS_DIR/../.." > /dev/null && pwd)"
factory_install_repo_root_dir="$(cd "$CURRENT_REPOSITORY_SCRIPTS_DIR/.." > /dev/null && pwd)"


export PKG_NIXOS_FACTORY_COMMON_INSTALL_WORKSPACE_DIR="$project_top_level_root_dir"
export PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_TYPE_DEFINITIONS_DIR="$factory_install_repo_root_dir"
# TODO: Move out of the factory install directory.
device_cfg_repo_root_dir="$(cd "$CURRENT_REPOSITORY_SCRIPTS_DIR/../demo-nixos-config" > /dev/null && pwd)"
# device_cfg_repo_root_dir="$factory_install_repo_root_dir"
export PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR="$device_cfg_repo_root_dir"

# Should help with developping scripts.
scripts_dir="$CURRENT_REPOSITORY_SCRIPTS_DIR"
export PKG_NIXOS_COMMON_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common"
export PKG_NIXOS_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common-install"
export PKG_NIXOS_DEVICE_SYSTEM_CONFIG_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/device-system-config"
export PKG_NIXOS_FACTORY_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/factory-common-install"
export PKG_NIXOS_FACTORY_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/factory-install"


export PKG_NIXOS_FACTORY_COMMON_INSTALL_WORKSPACE_DIR="$project_top_level_root_dir"
