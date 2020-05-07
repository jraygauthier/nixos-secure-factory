#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-sf-factory-common-install-get-libexec-dir)"
# Source both dependencies.
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/ssh.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"
. "$common_factory_install_libexec_dir/app_current_device_ssh.sh"


