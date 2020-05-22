#!/usr/bin/env bash
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_factory_ssh_known_hosts.sh"



print_factory_ssh_known_hosts_device_entry_cli() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  local kh_fn
  kh_fn="$(get_factory_ssh_known_hosts_filename)"

  print_title_lvl1 "Printing factory user known host entry for host '$kh_id'"

  local kg_args=( -f "$kh_fn" -H -F "$kh_id" )
  echo "$ ssh-keygen" "${kg_args[@]}"
  ssh-keygen "${kg_args[@]}"
}


rm_factory_ssh_known_hosts_device_entry_cli() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  print_title_lvl1 "Removing factory user known host entry for host '$kh_id'"

  rm_factory_ssh_known_hosts_current_device_entry
}


update_factory_ssh_known_hosts_device_entry_cli() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  print_title_lvl1 "Updating factory user known host entry for host '$kh_id'"

  update_factory_ssh_known_hosts_current_device_entry
}
