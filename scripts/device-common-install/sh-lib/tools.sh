#!/usr/bin/env bash
device_common_install_sh_lib_dir="$(pkg-nsf-device-common-install-get-sh-lib-dir)"
. "$device_common_install_sh_lib_dir/nixos.sh"

common_install_sh_lib_dir="$(pkg-nsf-common-install-get-sh-lib-dir)"
. "$common_install_sh_lib_dir/prettyprint.sh"

device_common_install_sh_lib_dir="$(pkg-nsf-device-common-install-get-sh-lib-dir)"
. "$device_common_install_sh_lib_dir/device_hw_validation.sh"
