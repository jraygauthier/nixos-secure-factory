#!/usr/bin/env bash
common_install_sh_lib_dir="$(pkg-nsf-common-install-get-sh-lib-dir)"
. "$common_install_sh_lib_dir/prettyprint.sh"

device_common_install_sh_lib_dir="$(pkg-nsf-device-common-install-get-sh-lib-dir)"
. "$device_common_install_sh_lib_dir/nixos.sh"
. "$device_common_install_sh_lib_dir/device_hw_validation.sh"
. "$device_common_install_sh_lib_dir/block_device_info.sh"
