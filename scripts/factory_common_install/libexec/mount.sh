#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
# From dependency libs.
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"
. "$common_install_libexec_dir/mount.sh"



