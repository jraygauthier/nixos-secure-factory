#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"

init_new_device_state_cli() {
  init_new_current_device_state_cli
}
