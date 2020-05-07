#!/usr/bin/env bash
# common_factory_install_libexec_dir="$(pkg-nixos-sf-factory-common-install-get-libexec-dir)"
# From dependency libs.
common_install_libexec_dir="$(pkg-nixos-sf-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/mount.sh"
