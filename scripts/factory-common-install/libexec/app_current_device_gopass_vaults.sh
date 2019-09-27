#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/gopass.sh"
. "$common_factory_install_libexec_dir/app_factory_gopass_vaults.sh"
. "$common_factory_install_libexec_dir/app_current_device_gpg.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"

# From deps libs.
common_install_libexec_dir="$(pkg-nixos-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/device_secrets.sh"


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
  local repo_store_key="$1"
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "${2:-}")"
  get_gopass_device_substore_key_impl "$repo_store_key" "$device_id"
}


get_gopass_cdevice_substore_key() {
  _get_gopass_cdevice_substore_key "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_cdevice_factory_only_substore_key() {
  _get_gopass_cdevice_substore_key "$(get_gopass_factory_only_vault_id)" "$@"
}


get_gopass_cdevice_substore_dir() {
  local repo_dir_parent
  repo_dir_parent="$(get_gopass_device_vault_repo_dir | xargs -L 1 dirname)" || return 1

  local sskey
  sskey="$(get_gopass_cdevice_substore_key "$@")" || return 1

  echo "$repo_dir_parent/$sskey"
}


get_gopass_cdevice_factory_only_substore_dir() {
  local repo_dir_parent
  repo_dir_parent="$(get_gopass_factory_only_vault_repo_dir | xargs -L 1 dirname)" || return 1

  local sskey
  sskey="$(get_gopass_cdevice_factory_only_substore_key "$@")" || return 1

  echo "$repo_dir_parent/$sskey"
}



exists_gopass_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  exists_gopass_device_substore "$device_id"
}


exists_gopass_factory_only_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  exists_gopass_factory_only_device_substore "$device_id"
}


mount_gopass_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"

  mount_gopass_device_substore "$device_id"
}


umount_gopass_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  umount_gopass_device_substore "$device_id"
}


mount_gopass_factory_only_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  mount_gopass_factory_only_device_substore "$device_id"
}


umount_gopass_factory_only_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  umount_gopass_factory_only_device_substore "$device_id"
}


mount_gopass_factory_cdevice_substores() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  mount_gopass_factory_device_substores "$device_id"
}


umount_gopass_factory_cdevice_substores() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  umount_gopass_factory_device_substores "$device_id"
}



rm_no_prompt_gopass_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  rm_no_prompt_gopass_device_substore "$device_id"
}


rm_no_prompt_gopass_factory_only_cdevice_substore() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  rm_no_prompt_gopass_factory_only_device_substore "$device_id"
}


rm_no_prompt_gopass_factory_cdevice_substores() {
  local device_id
  device_id="$(_ensure_gopass_device_id_or_current_device_id "$@")"
  rm_no_prompt_gopass_factory_device_substores "$device_id"
}


_get_gopass_device_full_store_key_for() {
  local repo_store_key="$1"
  local store_key="$2"
  local device_id="${3:-}"

  local device_store
  device_store="$(_get_gopass_cdevice_substore_key "$repo_store_key" "$device_id")"
  local full_store_key="${device_store}/${store_key}"

  # Remove all leading dot in filenames and directory components.
  # This seems to be poorly supported by gopass.
  local valid_full_store_key
  valid_full_store_key="$(echo "$full_store_key" | sed -E -e 's#/\.#/_#g')"
  echo "$valid_full_store_key"
}


get_gopass_device_full_store_key_for() {
  _get_gopass_device_full_store_key_for "$(get_gopass_device_vault_id)" "$@"
}


get_gopass_factory_only_device_full_store_key_for() {
  _get_gopass_device_full_store_key_for "$(get_gopass_factory_only_vault_id)" "$@"
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
    echo "ERROR: _ensure_exists_gopass_device_secret: Secret '${full_store_key}' does not exits!"
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


# TODO: Consider removing. Unreliable.
_store_gopass_device_text_secret_to_repo() {
  local repo_store_key="$1"
  local store_key="$2"
  local in_text="$3"
  local device_id="${4:-}"

  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo_store_key" "$store_key" "$device_id")"
  echo "Storing text secret to gopass '$full_store_key'."
  echo_eval "echo '$in_text' | factory-gopass --yes insert --force '$full_store_key'"
}


# TODO: Consider removing. Unreliable.
_store_gopass_device_text_file_secret_to_repo() {
  local repo_store_key="$1"
  local store_key="$2"
  local in_file="$3"
  local device_id="${4:-}"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo_store_key" "$store_key" "$device_id")"
  echo "Storing text file '$in_file' to gopass '$full_store_key'."
  echo_eval "cat '$in_file' | factory-gopass --yes insert --force '$full_store_key'"
}


_store_gopass_device_bin_file_secret_to_repo() {
  local repo_store_key="$1"
  local store_key="$2"
  local in_file="$3"
  local device_id="${4:-}"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo_store_key" "$store_key" "$device_id")"
  echo "Storing binary file '$in_file' to gopass '$full_store_key'."
  echo_eval "factory-gopass --yes binary cp --force '$in_file' '$full_store_key'"
}


# TODO: Consider removing. Unreliable.
store_gopass_device_text_secret() {
  _store_gopass_device_text_secret_to_repo "$(get_gopass_device_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
store_gopass_device_text_file_secret() {
  _store_gopass_device_text_file_secret_to_repo "$(get_gopass_device_vault_id)" "$@"
}


store_gopass_device_bin_file_secret() {
  _store_gopass_device_bin_file_secret_to_repo "$(get_gopass_device_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
store_gopass_factory_only_device_text_secret() {
  _store_gopass_device_text_secret_to_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
store_gopass_factory_only_device_text_file_secret() {
  _store_gopass_device_text_file_secret_to_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


store_gopass_factory_only_device_bin_file_secret() {
  _store_gopass_device_bin_file_secret_to_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
_load_gopass_device_text_secret_from_repo() {
  local repo_store_key="$1"
  local store_key="$2"
  local out_varname="$3"
  local device_id="${4:-}"
  _ensure_exists_gopass_device_secret "$repo_store_key" "$store_key" "$device_id" || return 1

  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo_store_key" "$store_key" "$device_id")"
  echo "Loading gopass text secret at '$full_store_key' to bash variable '$out_varname'."

  echo "out_val=\"\$(factory-gopass show -f '$full_store_key')\""
  local out_val
  out_val="$(factory-gopass show -f "$full_store_key")"
  if test "$(echo "$out_val" | wc -l)" -gt "1"; then
    # Gopass seems to trim trailing newlines on insert.
    # Ensure the secrets gets back its original newline.
    out_val="$(printf "%s\n" "${out_val}")"
  fi

  eval "${out_varname}='${out_val}'"
}


# TODO: Consider removing. Unreliable.
_load_gopass_device_text_file_secret_from_repo() {
  local repo_store_key="$1"
  local store_key="$2"
  local out_file="$3"
  local device_id="${4:-}"

  _ensure_exists_gopass_device_secret "$repo_store_key" "$store_key" "$device_id" || return 1

  local out_dirname
  out_dirname="$(dirname "$out_file")"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo_store_key" "$store_key" "$device_id")"
  echo "Loading gopass text secret at '$full_store_key' to file '$out_file'."
  mkdir -m 700 -p "$out_dirname"
  # Gopass seems to trim trailing newlines on insert.
  # Ensure the secrets gets back its original newline.
  echo_eval "factory-gopass show -f '$full_store_key' > '$out_file'" || return 1
  echo_eval "printf '\n' >> '$out_file'"
}


_load_gopass_device_bin_file_secret_from_repo() {
  local repo_store_key="$1"
  local store_key="$2"
  local out_file="$3"
  local device_id="${4:-}"

  _ensure_exists_gopass_device_secret "$repo_store_key" "$store_key" "$device_id" || return 1

  local out_dirname
  out_dirname="$(dirname "$out_file")"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo_store_key" "$store_key" "$device_id")"
  echo "Loading gopass binary secret at '$full_store_key' to file '$out_file'."
  mkdir -m 700 -p "$out_dirname"
  echo_eval "factory-gopass binary cp '$full_store_key' '$out_file'"
}


# TODO: Consider removing. Unreliable.
load_gopass_device_text_secret() {
  _load_gopass_device_text_secret_from_repo "$(get_gopass_device_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
load_gopass_device_text_file_secret() {
  _load_gopass_device_text_file_secret_from_repo "$(get_gopass_device_vault_id)" "$@"
}


load_gopass_device_bin_file_secret() {
  _load_gopass_device_bin_file_secret_from_repo "$(get_gopass_device_vault_id)" "$@"
}


load_gopass_factory_only_device_text_secret() {
  _load_gopass_device_text_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


# TODO: Consider removing. Unreliable.
load_gopass_factory_only_device_text_file_secret() {
  _load_gopass_device_text_file_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


load_gopass_factory_only_device_bin_file_secret() {
  _load_gopass_device_bin_file_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


_cat_gopass_device_bin_secret_from_repo() {
  _ensure_exists_gopass_device_secret "$@" || return 1

  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$@")"
  factory-gopass binary cat "$full_store_key"
}


cat_gopass_device_bin_secret() {
  _cat_gopass_device_bin_secret_from_repo "$(get_gopass_device_vault_id)" "$@"
}


cat_gopass_factory_only_device_bin_secret() {
  _cat_gopass_device_bin_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


list_gopass_cdevice_substore_peers_public_keys() {
  local device_sstore
  device_sstore="$(get_gopass_cdevice_substore_dir "$@")"

  local device_sub_store_pubkeys_dir
  device_sub_store_pubkeys_dir="$device_sstore/.public-keys"

  local pubkey_dirs=()

  if [[ -d "$device_sub_store_pubkeys_dir" ]]; then
    pubkey_dirs+=( "$device_sub_store_pubkeys_dir" )
  fi


  ([[ "${#pubkey_dirs[@]}" -eq 0 ]] || find "${pubkey_dirs[@]}" -mindepth 1 -maxdepth 1) \
    && list_factory_user_peers_pub_keys_from_gopass_vaults
}


list_authorized_gopass_cdevice_substores_peers_gpg_ids() {
  local device_sstore
  device_sstore="$(get_gopass_cdevice_substore_dir "$@")"

  local device_sub_store_gpg_id_file
  device_sub_store_gpg_id_file="$device_sstore/.gpg-id"

  (! [[ -f "$device_sub_store_gpg_id_file" ]] || cat "$device_sub_store_gpg_id_file") \
    && list_authorized_factory_user_peers_gpg_ids_from_gopass_vaults | sort | uniq
}


list_authorized_gopass_cdevice_substores_peers_public_keys() {
  local auth_gpg_ids
  auth_gpg_ids="$(list_authorized_gopass_cdevice_substores_peers_gpg_ids "$@")" || return 1
  local pubkey_files
  pubkey_files="$(list_gopass_cdevice_substore_peers_public_keys "$@")" || return 1
  _list_authorized_pub_key_files_from_authorized_gpg_ids_and_public_key_files \
    "$auth_gpg_ids" "$pubkey_files"
}


import_authorized_gopass_cdevice_substores_gpg_keys_to_factory_keyring() {
  local authorized_gpg_pub_keys
  authorized_gpg_pub_keys="$(list_authorized_gopass_cdevice_substores_peers_public_keys "$@")" || return 1

  while read -r pk; do
    local gpg_id_w_email
    gpg_id_w_email="$(list_gpg_id_w_email_from_armored_pub_key_stdin < "$pk")"
    echo "Importing '$gpg_id_w_email' into factory keyring."
    printf "$ factory-gpg --import '%s'\n" "$pk"
    factory-gpg --import "$pk"
  done < <(printf "%s\n" "$authorized_gpg_pub_keys")
}


list_authorized_gopass_cdevice_substores_peers_gpg_ids_w_email() {
  local peers_gpg_pub_keys
  mapfile -t peers_gpg_pub_keys < <(list_authorized_gopass_cdevice_substores_peers_public_keys) \
    || return 1

  list_gpg_id_w_email_from_key_files "${peers_gpg_pub_keys[@]}"
}


import_gpg_public_key_from_stdin_and_set_as_current() {
  local gpg_pub_key
  gpg_pub_key="$(cat -)"

  local gpg_id_from_pub_key
  gpg_id_from_pub_key="$(echo "$gpg_pub_key" | get_unique_gpg_id_from_armored_pub_key_stdin)"

  echo "$gpg_pub_key" | import_gpg_public_key_from_stdin_to_factory_keyring || return 1

  1>&2 store_current_device_gpg_id "$gpg_id_from_pub_key" || return 1
  device_gpg_key="$(get_device_gpg_id)" || return 1
}


load_cdevice_gpg_id_from_substore_and_set_as_current() {
  local gpg_pub_key
  gpg_pub_key="$(cat_gopass_factory_only_device_bin_secret "$(get_rel_gpg_public_key_filename)")"

  echo "$gpg_pub_key" | import_gpg_public_key_from_stdin_and_set_as_current
}


ensure_arg_gpg_id_or_device_current_gpg_id() {
  local device_gpg_key
  if [[ "x" == "${1:+x}" ]]; then
    device_gpg_key="$1"
  else
    if ! device_gpg_key="$(get_device_gpg_id 2>/dev/null)"; then
      if ! exists_gopass_factory_only_device_secret "$(get_rel_gpg_public_key_filename)"; then
        1>&2 echo "ERROR: No device gpg public public key stored. Cannat proceed with device autorization."
        return 1
      fi

      local gpg_pub_key
      gpg_pub_key="$(cat_gopass_factory_only_device_bin_secret "$(get_rel_gpg_public_key_filename)")"

      local gpg_id_from_pub_key
      gpg_id_from_pub_key="$(echo "$gpg_pub_key" | get_unique_gpg_id_from_armored_pub_key_stdin)"

      echo "$gpg_pub_key" | import_gpg_public_key_from_stdin_to_factory_keyring || return 1

      1>&2 store_current_device_gpg_id "$gpg_id_from_pub_key" || return 1
      device_gpg_key="$(get_device_gpg_id)" || return 1
    fi
  fi

  echo "$device_gpg_key"
}


list_device_non_current_gpg_ids() {
  local device_email
  device_email="$(get_required_current_device_email)"

  local key_list
  if ! key_list="$(list_factory_gpg_public_key_ids "$device_email")"; then
    return 1
  fi

  local device_gpg_id
  device_gpg_id="$(ensure_arg_gpg_id_or_device_current_gpg_id "$@")"
  if device_gpg_id="$(get_current_device_gpg_id 2>/dev/null)"; then
    if ! key_list="$(echo "$key_list" | grep -v "$device_gpg_id")"; then
      return 1
    fi
  fi

  echo "$key_list"
}


_deauthorize_gopass_cdevice_from_device_private_substore_prim() {
  local device_gpg_key
  device_gpg_key="$(ensure_arg_gpg_id_or_device_current_gpg_id "$@")"
  # echo "device_gpg_key='$device_gpg_key'"

  local device_private_substore
  device_private_substore="$(get_gopass_cdevice_substore_key)"

  deauthorize_gpg_id_from_gopass_store "$device_private_substore" "$device_gpg_key"
  delete_gpg_public_key_from_factory_keyring "$device_gpg_key" || return 1
}


deauthorize_gopass_cdevice_stale_gpg_keys_from_private_substore() {
  local device_gpg_key
  device_gpg_key="$(ensure_arg_gpg_id_or_device_current_gpg_id "$@")"

  local non_current_gpg_ids
  if ! non_current_gpg_ids="$(list_device_non_current_gpg_ids "$device_gpg_key")"; then
    # Nothing to do.
    return 0
  fi

  echo "non_current_gpg_ids='$non_current_gpg_ids'"

  while read -r old_gpg_id; do
    _deauthorize_gopass_cdevice_from_device_private_substore_prim "$old_gpg_id"
  done < <(printf "%s\n" "$non_current_gpg_ids")
}


_deauthorize_gopass_cdevice_stale_gpg_keys_from_private_substore_step() {
  local device_gpg_key="$1"

  # TODO: It won't be possible to do this automatically until we
  # have a way of retrieving device's state via ssh and store
  # it locally (secrets version / currently used gpg key).
  return 0

  # Ensure any non current device gpg key are deauthorized and deleted from
  # the keyring.
  print_title_lvl4 "Deauthorizing any non current device gpg key already in the factory user's keyring"
  deauthorize_gopass_cdevice_stale_gpg_keys_from_private_substore "$device_gpg_key" || return 1
}



deauthorize_gopass_cdevice_from_device_private_substore() {
  print_title_lvl3 "Deauthorize device from accessing its private sub-store"

  print_title_lvl4 "Importing gopass device authorized gpg keys to factory keyring"
  import_authorized_gopass_cdevice_substores_gpg_keys_to_factory_keyring "$@"

  local device_gpg_key
  device_gpg_key="$(ensure_arg_gpg_id_or_device_current_gpg_id "$@")"

  # Make sure we're not mistakenly trying to deauthorize ourself (factory user).
  if is_factory_gpg_id "$device_gpg_key"; then
    1>&2 echo "ERROR: Trying to deauthorize factory user's gpg id from gopass store. Unsupported operation."
    return 1
  fi

  _deauthorize_gopass_cdevice_stale_gpg_keys_from_private_substore_step "$device_gpg_key" || return 1

  print_title_lvl4 "Deauthorizing device gpg key stored in the vault itself"

  # if ! exists_gopass_factory_only_device_secret "$(get_rel_gpg_public_key_filename)"; then
  #   echo "No device gpg public public key stored. Nothing to do."
  #   return 0
  # fi
  #
  # cat_gopass_factory_only_device_bin_secret "$(get_rel_gpg_public_key_filename)" \
  #   | import_gpg_public_key_from_stdin_to_factory_keyring || return 1

  # echo "device_gpg_key='$device_gpg_key'"
  _deauthorize_gopass_cdevice_from_device_private_substore_prim "$device_gpg_key" || return 1

  echo_eval "factory-gopass --yes recipients"
}


authorize_gopass_cdevice_to_device_private_substore() {
  print_title_lvl3 "Authorize device access to its private sub-store"

  print_title_lvl4 "Importing gopass device authorized gpg keys to factory keyring"
  import_authorized_gopass_cdevice_substores_gpg_keys_to_factory_keyring "$@"

  local device_gpg_key
  device_gpg_key="$(ensure_arg_gpg_id_or_device_current_gpg_id "$@")"

  # echo "device_gpg_key='$device_gpg_key'"

  _deauthorize_gopass_cdevice_stale_gpg_keys_from_private_substore_step "$device_gpg_key" || return 1

  local device_private_substore
  device_private_substore="$(get_gopass_cdevice_substore_key)"

  local device_factory_only_substore
  device_factory_only_substore="$(get_gopass_cdevice_factory_only_substore_key)"

  print_title_lvl4 "Authorizing factory user peers to the device vaults"
  authorize_factory_user_peers_to_gopass_store "$device_private_substore"
  authorize_factory_user_peers_to_gopass_store "$device_factory_only_substore"

  print_title_lvl4 "Authorizing device gpg key its own private vault"
  authorize_gpg_id_to_gopass_store "$device_private_substore" "$device_gpg_key"

  echo_eval "factory-gopass --yes recipients"
}


