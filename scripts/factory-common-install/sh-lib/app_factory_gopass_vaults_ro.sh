#!/usr/bin/env bash
common_sh_lib_dir="$(pkg-nsf-common-get-sh-lib-dir)"
# shellcheck source=sh_stream.sh
. "$common_sh_lib_dir/sh_stream.sh"

common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_info_store.sh
. "$common_factory_install_sh_lib_dir/app_factory_info_store.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/workspace_paths.sh
. "$common_factory_install_sh_lib_dir/workspace_paths.sh"


get_gopass_device_vault_id() {
  local out_id
  out_id="$(get_required_factory_info__gopass_default_device_vault_id)"
  echo "$out_id"
}


get_gopass_factory_only_vault_id() {
  local out_id
  out_id="$(get_required_factory_info__gopass_factory_only_vault_id)"
  echo "$out_id"
}


get_gopass_device_vault_repo_dir() {
  local repo_name
  repo_name="$(get_required_factory_info__gopass_default_device_vault_repo_name)" \
    || return 1

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)" || return 1
  echo "$top_lvl/$repo_name"
}


get_gopass_factory_only_vault_repo_dir() {
  local repo_name
  repo_name="$(get_required_factory_info__gopass_factory_only_vault_repo_name)" \
    || return 1

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)" || return 1
  echo "$top_lvl/$repo_name"
}


get_gopass_device_substore_key_impl() {
  if ! [[ "x" == "${1:+x}" ]] || ! [[ "x" == "${2:+x}" ]]; then
    1>&2 echo "ERROR: get_gopass_device_substore_key_impl: missing argument."
    return 1
  fi

  local repo_store_key="$1"
  local device_id="$2"

  local device_store="$repo_store_key/device/$device_id"
  echo "$device_store"
}


get_gopass_device_substore_key() {
  get_gopass_device_substore_key_impl "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_device_factory_only_substore_key() {
  get_gopass_device_substore_key_impl "$(get_gopass_factory_only_vault_id)" "$@"
}


get_gopass_device_substore_dir() {
  local repo_dir_parent
  repo_dir_parent="$(get_gopass_device_vault_repo_dir | xargs -L 1 dirname)" || return 1

  local sskey
  sskey="$(get_gopass_device_substore_key "$@")" || return 1

  echo "$repo_dir_parent/$sskey"
}


get_gopass_device_factory_only_substore_dir() {
  local repo_dir_parent
  repo_dir_parent="$(get_gopass_factory_only_vault_repo_dir | xargs -L 1 dirname)" || return 1

  local sskey
  sskey="$(get_gopass_device_factory_only_substore_key "$@")" || return 1

  echo "$repo_dir_parent/$sskey"
}


exists_gopass_device_substore() {
  local ssdir
  ssdir="$(get_gopass_device_substore_dir "$@")" || return 1

  factory-gopass mounts | grep -q "$ssdir"
}


exists_gopass_factory_only_device_substore() {
  local ssdir
  ssdir="$(get_gopass_device_factory_only_substore_dir "$@")" || return 1

  factory-gopass mounts | grep -q "$ssdir"
}
