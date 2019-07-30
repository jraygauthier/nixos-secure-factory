#!/usr/bin/env bash
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"
. "$common_install_libexec_dir/prettyprint.sh"


is_device_cfg_repo_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device_type" && \
  test -d "$root_dir/device" && \
  test -f "$root_dir/release.nix"
}


is_device_cfg_repo_writable_root_dir() {
  local root_dir=${1:-$PWD}
  is_device_cfg_repo_root_dir "$root_dir" &&
  test -w "$root_dir" && \
  test -w "$root_dir/device_type" && \
  test -w "$root_dir/device" && \
  test -w "$root_dir"
}


is_nixos_secure_factory_repo_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device_type" && \
  test -d "$root_dir/scripts/device_common_install" && \
  test -d "$root_dir/scripts/factory_common_install"
}


is_factory_install_repo_root_dir() {
  local root_dir=${1:-$PWD}
  test -d "$root_dir/device_family" && \
  test -d "$root_dir/device_type" && \
  test -d "$root_dir/scripts/factory_install" && \
  test -f "$root_dir/enter_factory_install_scripts_env.sh"
}


is_factory_install_repo_writable_root_dir() {
  local root_dir=${1:-$PWD}
  is_factory_install_repo_root_dir "$root_dir" &&
  test -w "$root_dir"
}



get_device_cfg_repo_root_dir() {
  local root_dir_from_script=`cd "$(dirname $0)/../.." > /dev/null;pwd`
  # 1>&2 echo "root_dir_from_script=$root_dir"
  if is_device_cfg_repo_writable_root_dir "$root_dir_from_script"; then
    echo "$root_dir_from_script"
    return 0
  fi

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


get_factory_install_repo_root_dir() {
  local root_dir_from_script=`cd "$(dirname $0)/../.." > /dev/null;pwd`
  # 1>&2 echo "root_dir_from_script=$root_dir"
  if is_factory_install_repo_writable_root_dir "$root_dir_from_script"; then
    echo "$root_dir_from_script"
    return 0
  fi

  local root_dir=${PKG_NIXOS_FACTORY_COMMON_INSTALL_FACTORY_STATE_REPO_DIR:-$PWD}
  # 1>&2 echo "root_dir=$root_dir"
  if ! is_factory_install_repo_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Should either be executed from the factory install config "
    1>&2 printf -- "repo's root dir or env var \`PKG_NIXOS_FACTORY_COMMON_INSTALL_DEVICE_OS_CONFIG_REPO_DIR\` should "
    1>&2 printf -- "be set to point to the repository's root dir.\n"
    exit 1
  fi

  echo "$root_dir"
}


get_nixos_secure_factory_repo_root_dir() {
  # TODO: Consider overriding with a env?

  local pkg_libexec_dir
  pkg_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"

  local root_dir
  root_dir="$(cd "$pkg_libexec_dir/../../.." > /dev/null || exit 1; pwd)"

  if ! is_nixos_secure_factory_repo_root_dir "$root_dir"; then
    1>&2 printf -- "ERROR: Cannot resolve 'nixos_secure_factory' repository root."
    1>&2 printf -- " -> Please make sure your are executing the tool from a properly"
    1>&2 printf -- "    configured factory environement."
    exit 1
  fi

  echo "$root_dir"
}


get_factory_install_repo_parent_dir() {
  local repo_dir="$(get_factory_install_repo_root_dir)"
  local parent_dir=`cd "$repo_dir/.." > /dev/null;pwd`
  echo "$parent_dir"
}

