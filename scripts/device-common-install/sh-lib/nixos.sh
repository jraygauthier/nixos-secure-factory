#!/usr/bin/env bash
# device_common_install_sh_lib_dir="$(pkg-nixos-sf-device-common-install-get-sh-lib-dir)"
common_install_sh_lib_dir="$(pkg-nixos-sf-common-install-get-sh-lib-dir)"
. "$common_install_sh_lib_dir/mount.sh"
. "$common_install_sh_lib_dir/nixos.sh"
