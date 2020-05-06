#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"


run_all_devices_ssh_auth_dir_cli() {
  nixos-sf-ssh-auth-dir "$@"
}


run_device_ssh_auth_dir_cli() {
  nixos-sf-ssh-auth-dir "$@"
}
