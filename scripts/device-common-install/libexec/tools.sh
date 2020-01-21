#!/usr/bin/env bash
device_common_install_libexec_dir="$(pkg-nixos-device-common-install-get-libexec-dir)"
. "$device_common_install_libexec_dir/nixos.sh"

common_install_libexec_dir="$(pkg-nixos-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/prettyprint.sh"

device_common_install_libexec_dir="$(pkg-nixos-device-common-install-get-libexec-dir)"
. "$device_common_install_libexec_dir/device_hw_validation.sh"
