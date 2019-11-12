#!/usr/bin/env bash

is_device_cfg_repo_root_dir() {
  local root_dir=${1?}
  test -d "$root_dir/device" && \
  test -f "$root_dir/release.nix"
}


is_writable_device_cfg_repo_root_dir() {
  local root_dir=${1?}
  is_device_cfg_repo_root_dir "$root_dir" && \
  test -w "$root_dir"
}


get_device_cfg_repo_root_dir() {
  # TODO: What occurs when `PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR`
  # does not exists? Shouldn't we take this information from `.factory-info.yaml`?
  local root_dir=${PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR?}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_device_cfg_repo_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var'PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR' "
    1>&2 printf -- "should be set to point to the device configuration core repository\n"
    exit 1
  fi

  echo "$root_dir"
}


get_writable_device_cfg_repo_root_dir() {
  local root_dir
  root_dir="$(get_device_cfg_repo_root_dir)"
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_writable_device_cfg_repo_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var'PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR' "
    1>&2 printf -- "should be set to point to a writable version of the device configuration "
    1>&2 printf -- "repository\n"
    exit 1
  fi

  echo "$root_dir"
}


is_factory_install_device_type_definitions_root_dir() {
  local root_dir=${1?}
  # No simple way to validate this.
  true
}


get_factory_install_device_type_definitions_root_dir() {
  # TODO: What occurs when `PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_TYPE_FACTORY_INSTALL_DEFS_DIR`
  # does not exists? Shouldn't we take this information from `.factory-info.yaml`?

  local root_dir=${PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_TYPE_FACTORY_INSTALL_DEFS_DIR?}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_factory_install_device_type_definitions_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var 'PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_TYPE_FACTORY_INSTALL_DEFS_DIR' should "
    1>&2 printf -- "be set to point to the directory where device type factory install definitions can be found.\n"
    exit 1
  fi

  echo "$root_dir"
}



is_device_cfg_type_definitions_root_dir() {
  local root_dir=${1?}
  # No simple way to validate this.
  true
}


get_device_cfg_type_definitions_root_dir() {
  # TODO: What occurs when `PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_TYPE_DEFS_DIR`
  # does not exists? Shouldn't we take this information from `.factory-info.yaml`?

  local root_dir=${PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_TYPE_DEFS_DIR?}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_device_cfg_type_definitions_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var 'PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_TYPE_DEFS_DIR' should "
    1>&2 printf -- "be set to point to the directory where device config type definitions can be found.\n"
    exit 1
  fi

  echo "$root_dir"
}


is_device_cfg_ssh_auth_root_dir() {
  local root_dir=${1?}
  # No simple way to validate this.
  true
}


get_device_cfg_ssh_auth_root_dir() {
  # TODO: What occurs when `PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_TYPE_DEFS_DIR`
  # does not exists? Shouldn't we take this information from `.factory-info.yaml`?

  local root_dir=${PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_SSH_AUTH_DIR?}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_device_cfg_ssh_auth_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var 'PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_SSH_AUTH_DIR' should "
    1>&2 printf -- "be set to point to the directory where device configuration ssh authorization "
    1>&2 printf -- "files can be found.\n"
    exit 1
  fi

  echo "$root_dir"
}


is_writable_device_cfg_ssh_auth_root_dir() {
  is_device_cfg_ssh_auth_root_dir "$root_dir" && \
  test -w "$root_dir"
}


get_writable_device_cfg_ssh_auth_root_dir() {
  local root_dir
  root_dir="$(get_device_cfg_ssh_auth_root_dir)"
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_writable_device_cfg_ssh_auth_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var'PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_DEVICE_CONFIG_SSH_AUTH_DIR' "
    1>&2 printf -- "should be set to point to a writable version of the device config ssh "
    1>&2 printf -- "authorization directory\n"
    exit 1
  fi

  echo "$root_dir"
}


get_nixos_secure_factory_workspace_dir() {
  local ws_dir
  ws_dir="$(pkg-nixos-factory-common-install-get-workspace-dir)"
  echo "$ws_dir"
}
