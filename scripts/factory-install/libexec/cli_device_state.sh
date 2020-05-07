#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-sf-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"

init_new_device_state_cli() {
  init_new_current_device_state_cli
}
