#!/usr/bin/env bash
# device_common_install_libexec_dir="$(pkg_nixos_device_common_install_get_libexec_dir)"
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"
. "$common_install_libexec_dir/mount.sh"
. "$common_install_libexec_dir/nixos.sh"
