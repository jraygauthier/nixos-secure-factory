#!/usr/bin/env bash
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_current_device_ssh.sh"


get_current_device_known_hosts_id() {
  local device_hostname
  device_hostname="$(get_required_current_device_hostname)" || return 1
  local device_ssh_port
  device_ssh_port="$(get_required_current_device_ssh_port)" || return 1

  local kh_id
  kh_id="$(build_knownhost_id_from_hostname_and_opt_port \
    "$device_hostname" "$device_ssh_port")" || return 1

  echo "$kh_id"
}


get_factory_ssh_known_hosts_filename() {
  echo "$HOME/.ssh/known_hosts"
}


rm_factory_ssh_known_hosts() {
  local kh_id="${1?}"

  local kh_fn
  kh_fn="$(get_factory_ssh_known_hosts_filename)"

  local kg_args=( -f "$kh_fn" -R "$kh_id" )
  echo "$ ssh-keygen" "${kg_args[@]}"
  ssh-keygen "${kg_args[@]}"
}


rm_factory_ssh_known_hosts_current_device_entry() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  rm_factory_ssh_known_hosts "$kh_id"
}


update_factory_ssh_known_hosts_current_device_entry() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  local kh_fn
  kh_fn="$(get_factory_ssh_known_hosts_filename)"

  rm_factory_ssh_known_hosts "$kh_fn"
}


print_factory_ssh_known_hosts_device_entry_cli() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  local kh_fn
  kh_fn="$(get_factory_ssh_known_hosts_filename)"

  local kg_args=( -f "$kh_fn" -H -F "$kh_id" )
  echo "$ ssh-keygen" "${kg_args[@]}"
  ssh-keygen "${kg_args[@]}"
}


rm_factory_ssh_known_hosts_device_entry_cli() {
  rm_factory_ssh_known_hosts_current_device_entry
}


update_factory_ssh_known_hosts_device_entry_cli() {
  update_factory_ssh_known_hosts_current_device_entry
}
