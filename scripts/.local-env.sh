#!/usr/bin/env bash

# Meant to be sourced.
# Depends on 'CURRENT_REPOSITORY_SCRIPTS_DIR' being set to this script's dir.

project_top_level_root_dir="$(cd "$CURRENT_REPOSITORY_SCRIPTS_DIR/../.." > /dev/null && pwd)"
factory_install_repo_root_dir="$(cd "$CURRENT_REPOSITORY_SCRIPTS_DIR/.." > /dev/null && pwd)"


export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_WORKSPACE_DIR="$project_top_level_root_dir"
export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_TYPE_FACTORY_INSTALL_DEFS_DIR="$factory_install_repo_root_dir/device-type"
# TODO: Move out of the factory install directory.
device_cfg_repo_root_dir="$(cd "$CURRENT_REPOSITORY_SCRIPTS_DIR/../demo-nixos-config" > /dev/null && pwd)"
# device_cfg_repo_root_dir="$factory_install_repo_root_dir"
export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR="$device_cfg_repo_root_dir"
export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_TYPE_DEFS_DIR="$device_cfg_repo_root_dir/device-type"
export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_SSH_AUTH_DIR="$device_cfg_repo_root_dir/device-ssh/authorized"

# Should help with developping scripts.
scripts_dir="$CURRENT_REPOSITORY_SCRIPTS_DIR"
export PKG_NIXOS_SF_COMMON_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common"
export PKG_NIXOS_SF_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common-install"
export PKG_NIXOS_SF_DEVICE_SYSTEM_CONFIG_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/device-system-config"
export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/factory-common-install"
export PKG_NIXOS_SF_FACTORY_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/factory-install"


export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_WORKSPACE_DIR="$project_top_level_root_dir"
