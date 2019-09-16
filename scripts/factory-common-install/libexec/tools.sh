#!/usr/bin/env bash
common_install_libexec_dir="$(pkg-nixos-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/prettyprint.sh"


is_device_cfg_repo_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device-type" && \
  test -d "$root_dir/device" && \
  test -f "$root_dir/release.nix"
}


is_device_cfg_repo_writable_root_dir() {
  local root_dir=${1:-$PWD}
  is_device_cfg_repo_root_dir "$root_dir" &&
  test -w "$root_dir" && \
  test -w "$root_dir/device-type" && \
  test -w "$root_dir/device" && \
  test -w "$root_dir"
}


is_nixos_secure_factory_repo_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device-type" && \
  test -d "$root_dir/scripts/device-common-install" && \
  test -d "$root_dir/scripts/factory-common-install"
}


is_factory_install_repo_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device-family" && \
  test -d "$root_dir/device-type" && \
  test -d "$root_dir/scripts/factory-install" && \
  test -f "$root_dir/enter-factory-install-scripts-env.sh"
}


is_factory_install_device_type_definitions_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device-family" && \
  test -d "$root_dir/device-type"
}


is_factory_install_repo_writable_root_dir() {
  local root_dir=${1:-$PWD}
  is_factory_install_repo_root_dir "$root_dir" &&
  test -w "$root_dir"
}


get_device_cfg_repo_root_dir() {
  # TODO: What occurs when `PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR`
  # does not exists? Shouldn't we take this information from `.factory-info.yaml`?
  local root_dir=${PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR:-$PWD}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_device_cfg_repo_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Should either be executed from the factory install config "
    1>&2 printf -- "repo's root dir or env var \`PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR\` should "
    1>&2 printf -- "be set to point to the repository's root dir.\n"
    exit 1
  fi

  echo "$root_dir"
}


get_factory_install_device_type_definitions_root_dir() {
  # TODO: What occurs when `PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_TYPE_DEFINITIONS_DIR`
  # does not exists? Shouldn't we take this information from `.factory-info.yaml`?

  local root_dir=${PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_TYPE_DEFINITIONS_DIR:-$PWD}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_factory_install_device_type_definitions_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Env var \`PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_TYPE_DEFINITIONS_DIR\` should "
    1>&2 printf -- "be set to point to the directory where device type definitions can be found.\n"
    exit 1
  fi

  echo "$root_dir"
}


get_nixos_secure_factory_workspace_dir() {
  local ws_dir
  ws_dir="$(pkg-nixos-factory-common-install-get-workspace-dir)"
  echo "$ws_dir"
}
