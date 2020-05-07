#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# Source both dependencies.
. "$common_factory_install_sh_lib_dir/tools.sh"
. "$common_factory_install_sh_lib_dir/ssh.sh"
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"
. "$common_factory_install_sh_lib_dir/app_current_device_ssh.sh"


