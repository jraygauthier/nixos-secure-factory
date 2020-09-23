#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_gopass_vaults.sh
. "$common_factory_install_sh_lib_dir/app_factory_gopass_vaults_ro.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"

common_install_sh_lib_dir="$(pkg-nsf-common-install-get-sh-lib-dir)"
# shellcheck source=device_secrets.sh
. "$common_install_sh_lib_dir/device_secrets.sh"


_ensure_gopass_device_id_or_current_device_id() {
  local device_id
  if [[ "x" == "${1:+x}" ]]; then
    device_id="$1"
  else
    device_id="$(get_required_current_device_id)" || return 1
  fi
  echo "$device_id"
}


_get_gopass_cdevice_substore_key() {
  local repo_store_key="${1?}"
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "${2:-}")" || return 1
  get_gopass_device_substore_key_impl "$repo_store_key" "$device_id"
}


get_gopass_cdevice_substore_key() {
  _get_gopass_cdevice_substore_key "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_cdevice_factory_only_substore_key() {
  _get_gopass_cdevice_substore_key "$(get_gopass_factory_only_vault_id)" "$@"
}


_get_gopass_cdevice_substore_dir() {
  local repo_dir_parent
  repo_dir_parent="$(get_gopass_device_vault_repo_dir | xargs -L 1 dirname)" || return 1

  local sskey
  sskey="$(_get_gopass_cdevice_substore_key "$@")" || return 1

  echo "$repo_dir_parent/$sskey"
}


get_gopass_cdevice_substore_dir() {
  _get_gopass_cdevice_substore_dir "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_cdevice_factory_only_substore_dir() {
  _get_gopass_cdevice_substore_dir "$(get_gopass_factory_only_vault_id)" "$@"
}


exists_gopass_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")" || return 1
  exists_gopass_device_substore "$device_id"
}


exists_gopass_factory_only_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")" || return 1
  exists_gopass_factory_only_device_substore "$device_id"
}


_get_gopass_device_secrets_store_key_prefix() {
  # Device secrets will be stored under a "secrets" directory.
  echo "secrets/"
}


_get_gopass_device_relative_store_key_for() {
  local store_key="${1?}"

  local store_key_prefix
  store_key_prefix="$(_get_gopass_device_secrets_store_key_prefix)" || return 1
  local rel_store_key="${store_key_prefix}${store_key}"

  # Remove all leading dot in filenames and directory components.
  # This seems to be poorly supported by gopass.
  local valid_rel_store_key
  valid_rel_store_key="$(echo "$rel_store_key" | sed -E -e 's#/\.#/_#g')" || return 1
  echo "$valid_rel_store_key"
}


_get_gopass_device_full_store_key_for() {
  local repo_store_key="${1?}"
  local store_key="${2?}"
  local device_id="${3:-}"

  local device_store
  device_store="$(_get_gopass_cdevice_substore_key "$repo_store_key" "$device_id")" || return 1

  local valid_rel_store_key
  valid_rel_store_key="$(_get_gopass_device_relative_store_key_for "$store_key")"
  local valid_full_store_key="${device_store}/${valid_rel_store_key}"
  echo "$valid_full_store_key"
}


get_gopass_device_full_store_key_for() {
  _get_gopass_device_full_store_key_for "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_factory_only_device_full_store_key_for() {
  _get_gopass_device_full_store_key_for "$(get_gopass_factory_only_vault_id)" "$@"
}


_get_gopass_device_full_store_path_for() {
  local repo_store_key="${1?}"
  local store_key="${2?}"
  local device_id="${3:-}"

  local device_store_dir
  device_store_dir="$(_get_gopass_cdevice_substore_dir "$repo_store_key" "$device_id")" || return 1

  local valid_rel_store_key
  valid_rel_store_key="$(_get_gopass_device_relative_store_key_for "$store_key")" || return 1
  local valid_full_path="${device_store_dir}/${valid_rel_store_key}"
  echo "$valid_full_path"
}


_get_gopass_device_full_store_bin_secret_path_for() {
  local valid_full_path
  valid_full_path="$(_get_gopass_device_full_store_path_for "$@")" || return 1
  echo "${valid_full_path}.b64.gpg"
}


get_gopass_device_full_store_bin_secret_path_for() {
  _get_gopass_device_full_store_bin_secret_path_for "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_factory_only_device_full_store_bin_secret_path_for() {
  _get_gopass_device_full_store_bin_secret_path_for "$(get_gopass_factory_only_vault_id)" "$@"
}


_exists_gopass_device_secret() {
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$@")" || return 1

  local all_secrets
  all_secrets="$(factory-gopass ls -f)" || return 1

  # echo "$all_secrets" | grep "${full_store_key}"

  local binary_ext=".b64"
  local text_ext=""
  echo "$all_secrets" | grep -E "^${full_store_key}${binary_ext}$" > /dev/null \
    || echo "$all_secrets" | grep -E "^${full_store_key}${text_ext}$" > /dev/null
}


_ensure_exists_gopass_device_secret() {
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$@")" || return 1
  if ! _exists_gopass_device_secret "$@"; then
    1>&2 echo "ERROR: _ensure_exists_gopass_device_secret: Secret '${full_store_key}' does not exits!"
    return 1
  fi
}


_exists_gopass_device_text_secret() {
  _ensure_exists_gopass_device_secret "$@" || return 1

  local all_secrets
  all_secrets="$(factory-gopass ls -f)" || return 1

  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$@")"
  local text_ext=""
  echo "$all_secrets" | grep -E "^${full_store_key}${text_ext}$" > /dev/null
}


exists_gopass_device_secret() {
  _exists_gopass_device_secret "$(get_gopass_device_vault_id)" "$@"
}


ensure_exists_gopass_device_secret() {
  _ensure_exists_gopass_device_secret "$(get_gopass_device_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
exists_gopass_device_text_secret() {
  _exists_gopass_device_text_secret "$(get_gopass_device_vault_id)" "$@"
}


exists_gopass_factory_only_device_secret() {
  _exists_gopass_device_secret "$(get_gopass_factory_only_vault_id)" "$@"
}


ensure_exists_gopass_factory_only_device_secret() {
  _ensure_exists_gopass_device_secret "$(get_gopass_factory_only_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
exists_gopass_factory_only_device_text_secret() {
  _exists_gopass_device_text_secret "$(get_gopass_factory_only_vault_id)" "$@"
}


_cat_gopass_device_bin_secret_from_repo() {
  _ensure_exists_gopass_device_secret "$@" || return 1

  local full_path
  full_path="$(_get_gopass_device_full_store_bin_secret_path_for "$@")"
  factory-gpg -d "$full_path" 2>/dev/null | base64 -d -
}


cat_gopass_device_bin_secret() {
  _cat_gopass_device_bin_secret_from_repo "$(get_gopass_device_vault_id)" "$@"
}


cat_gopass_factory_only_device_bin_secret() {
  _cat_gopass_device_bin_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


_get_by_ref_gopass_device_bin_secret_from_repo() {
  declare -n _out_decrypted_secret="${1?}"
  shift 1

  _ensure_exists_gopass_device_secret "$@" || return 1

  local full_path
  full_path="$(_get_gopass_device_full_store_bin_secret_path_for "$@")"

  local gpg_args=( -d "$full_path" )
  local base64_args=( -d "-" )

  printf "$ factory-gpg "
  printf "%q " "${gpg_args[@]}"
  printf "2>/dev/null | base64"
  printf "%q " "${base64_args[@]}"
  printf "\n"
  # shellcheck disable=SC2034
  _out_decrypted_secret="$(factory-gpg "${gpg_args[@]}" 2>/dev/null | base64 "${base64_args[@]}")"
  printf "%s\n" "$_out_decrypted_secret"
}


get_by_ref_gopass_device_bin_secret() {
  local _out_vn="${1?}"
  shift 1
  _get_by_ref_gopass_device_bin_secret_from_repo "$_out_vn" "$(get_gopass_device_vault_id)" "$@"
}


get_by_ref_gopass_factory_only_device_bin_secret() {
  local _out_vn="${1?}"
  shift 1
  _get_by_ref_gopass_device_bin_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}
