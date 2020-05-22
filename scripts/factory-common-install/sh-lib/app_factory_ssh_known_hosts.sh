#!/usr/bin/env bash
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_current_device_ssh.sh"
. "$common_factory_install_sh_lib_dir/app_current_device_secrets_ro.sh"



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

  local host_pk
  get_by_ref_device_host_ssh_public_key "host_pk" || return 1

  local host_pk_no_comments
  host_pk_no_comments="$(echo "$host_pk" | awk '{ printf "%s %s", $1, $2}')"

  # Do not fail as it might not exists.
  rm_factory_ssh_known_hosts "$kh_id" || true

  local kh_new_entry
  kh_new_entry="${kh_id} ${host_pk_no_comments}"

  echo "$ echo '$kh_new_entry' >> '$kh_fn'"
  echo "$kh_new_entry" >> "$kh_fn"
}
