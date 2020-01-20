#!/usr/bin/env bash

current_package_root_dir_env_var_name="NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR"
current_package_root_dir="$NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR"

if [[ "" == "$current_package_root_dir" ]]; then
  1>&2 echo "ERROR: '$current_package_root_dir_env_var_name' env var should be set."
  exit 1
fi

if ! [[ -f "$current_package_root_dir/bin/pkg-nixos-factory-install-get-root-dir" ]]; then
  1>&2 echo "ERROR: '$current_package_root_dir_env_var_name' env var should point to a valid" \
    "path to factory install package sources."
  exit 1
fi

CURRENT_PACKAGE_ROOT_DIR="$current_package_root_dir"
! test -e "$CURRENT_PACKAGE_ROOT_DIR/.local-env.sh" || \
  . "$CURRENT_PACKAGE_ROOT_DIR/.local-env.sh"
unset CURRENT_PACKAGE_ROOT_DIR

# TODO: Check that proper sshd version is installed.
# TODO: Check that proper VBox version is installed.
