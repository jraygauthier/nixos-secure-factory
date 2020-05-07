#!/usr/bin/env bash
current_pkg_root_dir_env_var_name="PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_PACKAGE_ROOT_DIR"

if ! current_pkg_root_dir="$(printenv "$current_pkg_root_dir_env_var_name")" \
    || [[ "" == "$current_pkg_root_dir" ]]; then
  1>&2 echo "ERROR: '$current_pkg_root_dir_env_var_name' env var should be set."
  exit 1
fi

if ! [[ -f "$current_pkg_root_dir/bin/pkg-nixos-sf-factory-common-install-get-root-dir" ]]; then
  1>&2 echo "ERROR: '$current_pkg_root_dir_env_var_name' env var should point to a valid" \
    "path to factory common install package sources."
  exit 1
fi

CURRENT_PKG_ROOT_DIR="$current_pkg_root_dir"
! test -e "$CURRENT_PKG_ROOT_DIR/.local-env.sh" || \
  . "$CURRENT_PKG_ROOT_DIR/.local-env.sh"
unset CURRENT_PKG_ROOT_DIR
