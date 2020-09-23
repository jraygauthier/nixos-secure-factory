#!/usr/bin/env bash

common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_ssh.sh
. "$common_factory_install_sh_lib_dir/app_factory_ssh.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_ssh.sh
. "$common_factory_install_sh_lib_dir/app_current_device_ssh.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_secrets_ro.sh
. "$common_factory_install_sh_lib_dir/app_current_device_secrets_ro.sh"



get_factory_ssh_known_hosts_filename() {
  echo "$HOME/.ssh/known_hosts"
}


rm_factory_ssh_known_hosts() {
  local kh_id="${1?}"

  local kh_fn
  kh_fn="$(get_factory_ssh_known_hosts_filename)"

  local kg_args=( -f "$kh_fn" -R "$kh_id" )
  printf "$ ssh-keygen "
  printf "%q " "${kg_args[@]}"
  printf "\n"
  ssh-keygen "${kg_args[@]}"
}


rm_factory_ssh_known_hosts_current_device_entry() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)"

  rm_factory_ssh_known_hosts "$kh_id"
}


select_host_algo_shared_by_factory_ssh_client_and_device() {
  declare -a host_algos
  mapfile -t host_algos < <(list_expected_device_host_ssh_key_types)

  local common_algos
  if ! common_algos="$(list_ssh_prefered_host_key_algos_in_set "${host_algos[@]}")"; then
    1>&2 echo "WARNING: ${FUNCNAME[0]}: no shared algo between host and ssh client."
    1>&2 echo " -> Fallbacking on using the host's prefered algo. Note that it might fail."
    common_algos="$(printf "%s\n" "${host_algos[@]}")"
  fi

  local selected_algo
  selected_algo="$(echo "$common_algos" | head -n 1)"
  if ! [[ "" != "${selected_algo}" ]]; then
    1>&2 echo "ERROR: ${FUNCNAME[0]}: unexpectedly found no algo."
    return 1
  fi
  echo "$selected_algo"
}


update_factory_ssh_known_hosts_current_device_entry() {
  local kh_id
  kh_id="$(get_current_device_known_hosts_id)" || return 1

  local kh_fn
  kh_fn="$(get_factory_ssh_known_hosts_filename)" || return 1

  local selected_algo
  selected_algo="$(select_host_algo_shared_by_factory_ssh_client_and_device)" || return 1

  local host_pk
  get_by_ref_device_host_ssh_public_key "host_pk" "$selected_algo" || return 1
  printf "\n"

  local host_pk_no_comments
  host_pk_no_comments="$(echo "$host_pk" | awk '{ printf "%s %s", $1, $2}')"

  # Do not fail as it might not exists.
  rm_factory_ssh_known_hosts "$kh_id" || true
  printf "\n"

  local kh_new_entry
  kh_new_entry="${kh_id} ${host_pk_no_comments}"

  echo "$ echo '$kh_new_entry' >> '$kh_fn'"
  echo "$kh_new_entry" >> "$kh_fn"
}
