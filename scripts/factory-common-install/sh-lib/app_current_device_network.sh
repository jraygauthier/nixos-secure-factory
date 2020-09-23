#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store_iactive.sh
. "$common_factory_install_sh_lib_dir/app_current_device_store_iactive.sh"


ping_device() {
  local device_hostname
  # shellcheck disable=SC2120
  read_or_prompt_for_current_device__hostname "device_hostname"

  local ping_args_a=( "$@" "${device_hostname}" )

  echo " -> ping" "${ping_args_a[@]}"
  ping "${ping_args_a[@]}"
}
