#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/gopass.sh"
. "$common_factory_install_libexec_dir/app_factory_gopass.sh"
. "$common_factory_install_libexec_dir/app_current_device_gpg.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"

# From deps libs.
common_install_libexec_dir="$(pkg-nixos-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/device_secrets.sh"


exists_gopass_device_secrets() {
  local device_id="${1:-}"
  test "" != "$device_id" \
    || device_id="$(get_required_current_device_id)" \
    || exit 1
  gopass ls -f -fo "$(get_gopass_device_vault_id)/${device_id}" &> /dev/null
}


exists_gopass_factory_only_device_secrets() {
  local device_id="${1:-}"
  test "" != "$device_id" \
    || device_id="$(get_required_current_device_id)" \
    || exit 1
  gopass ls -f -fo  "$(get_gopass_factory_only_vault_id)/${device_id}" &> /dev/null
}


mount_gopass_device() {
  print_title_lvl5 "mount_gopass_device"

  local device_id="${1:-}"
  test "" != "$device_id" \
    || device_id="$(get_required_current_device_id)" \
    || exit 1

  # device_gpg_key

  if exists_gopass_device_secrets "$device_id"; then
    echo "Device secret store already exists."
    return 0
  fi

  local factory_gpg_key_id
  read_or_prompt_for_factory_info__user_gpg_default_id "factory_gpg_key_id"
  local top_lvl
  top_lvl="$(get_factory_install_repo_parent_dir)"

  echo_eval "gopass mounts add -i '$factory_gpg_key_id'" \
    "'$(get_gopass_device_vault_id)/$device_id'" \
    "'$top_lvl/$(get_gopass_device_vault_id)/$device_id'"

  # TODO grant access to device gpgid
}


umount_gopass_device() {
  print_title_lvl5 "umount_gopass_device"

  local device_id="${1:-}"
  test "" != "$device_id" \
    || device_id="$(get_required_current_device_id)" \
    || exit 1

  if ! exists_gopass_device_secrets "$device_id"; then
    echo "Device secret store does not exists. Nothing to unmount."
    return 0
  fi

  echo_eval "gopass mounts remove '$(get_gopass_device_vault_id)/$device_id'"
}


rm_no_prompt_gopass_device() {
  print_title_lvl5 "rm_no_prompt_gopass_device"

  local device_id="${1:-}"
  test "" != "$device_id" \
    || device_id="$(get_required_current_device_id)" \
    || exit 1

  if ! exists_gopass_device_secrets "$device_id"; then
    echo "Device secret store does not exists. Nothing to remove."
    return 0
  fi

  umount_gopass_device "$device_id"
  echo_eval "gopass --yes rm -r '$(get_gopass_device_vault_id)/$device_id'"
}


rm_no_prompt_gopass_factory_only_device() {
  print_title_lvl5 "rm_no_prompt_gopass_factory_only_device"

  local device_id="${1:-}"
  test "" != "$device_id" \
    || device_id="$(get_required_current_device_id)" \
    || exit 1

  if ! exists_gopass_factory_only_device_secrets "$device_id"; then
    echo "Factory only device secret store does not exists. Nothing to remove."
    return 0
  fi

  umount_gopass_device "$device_id"
  echo_eval "gopass --yes rm -r '$(get_gopass_factory_only_vault_id)/$device_id'"
}


_get_gopass_device_substore_key() {
  local repo="$1"
  local device_id
  device_id="$(get_required_current_device_id)" || exit 1
  local device_store="$repo/$device_id"
  echo "$device_store"
}


get_gopass_device_substore_key() {
  _get_gopass_device_substore_key "$(get_gopass_device_vault_id)"
}


get_gopass_factory_only_substore_key() {
  _get_gopass_device_substore_key "$(get_gopass_factory_only_vault_id)"
}


_get_gopass_device_full_store_key_for() {
  local repo="$1"
  local store_key="$2"

  local device_store
  device_store="$(_get_gopass_device_substore_key "$repo")"
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
  full_store_key="$(_get_gopass_device_full_store_key_for "$@")"
  gopass ls -f | grep -q "${full_store_key}"
}


_ensure_exists_gopass_device_secret() {
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$@")"
  if ! _exists_gopass_device_secret "$@"; then
    echo "ERROR: _ensure_exists_gopass_device_secret: Secret '${full_store_key}' does not exits!"
    return 1
  fi
}


_exists_gopass_device_text_secret() {
  local repo="$1"
  local store_key="$2"
  local full_store_key

  _ensure_exists_gopass_device_secret "$@" || return 1

  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  local binary_ext="b64"
  ! gopass ls -f | grep -q "${full_store_key}.${binary_ext}"
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
  local repo="$1"
  local store_key="$2"
  local in_text="$3"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  echo "Storing text secret to gopass '$full_store_key'."
  echo_eval "echo '$in_text' | gopass --yes insert --force '$full_store_key'"
}


# TODO: Consider removing. Unreliable.
_store_gopass_device_text_file_secret_to_repo() {
  local repo="$1"
  local store_key="$2"
  local in_file="$3"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  echo "Storing text file '$in_file' to gopass '$full_store_key'."
  echo_eval "cat '$in_file' | gopass --yes insert --force '$full_store_key'"
}


_store_gopass_device_bin_file_secret_to_repo() {
  local repo="$1"
  local store_key="$2"
  local in_file="$3"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  echo "Storing binary file '$in_file' to gopass '$full_store_key'."
  echo_eval "gopass --yes binary cp --force '$in_file' '$full_store_key'"
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
  local repo="$1"
  local store_key="$2"
  local out_varname="$3"
  _ensure_exists_gopass_device_secret "$repo" "$store_key" || return 1

  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  echo "Loading gopass text secret at '$full_store_key' to bash variable '$out_varname'."

  echo "out_val=\"\$(gopass show -f '$full_store_key')\""
  local out_val
  out_val="$(gopass show -f "$full_store_key")"
  if test "$(echo "$out_val" | wc -l)" -gt "1"; then
    # Gopass seems to trim trailing newlines on insert.
    # Ensure the secrets gets back its original newline.
    out_val="$(printf "%s\n" "${out_val}")"
  fi

  eval "${out_varname}='${out_val}'"
}


# TODO: Consider removing. Unreliable.
_load_gopass_device_text_file_secret_from_repo() {
  local repo="$1"
  local store_key="$2"
  local out_file="$3"

  _ensure_exists_gopass_device_secret "$repo" "$store_key" || return 1

  local out_dirname
  out_dirname="$(dirname "$out_file")"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  echo "Loading gopass text secret at '$full_store_key' to file '$out_file'."
  mkdir -m 700 -p "$out_dirname"
  # Gopass seems to trim trailing newlines on insert.
  # Ensure the secrets gets back its original newline.
  echo_eval "gopass show -f '$full_store_key' > '$out_file'" || return 1
  echo_eval "printf '\n' >> '$out_file'"
}


_load_gopass_device_bin_file_secret_from_repo() {
  local repo="$1"
  local store_key="$2"
  local out_file="$3"

  _ensure_exists_gopass_device_secret "$repo" "$store_key" || return 1

  local out_dirname
  out_dirname="$(dirname "$out_file")"
  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  echo "Loading gopass binary secret at '$full_store_key' to file '$out_file'."
  mkdir -m 700 -p "$out_dirname"
  echo_eval "gopass binary cp '$full_store_key' '$out_file'"
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
  local repo="$1"
  local store_key="$2"

  _ensure_exists_gopass_device_secret "$repo" "$store_key" || return 1

  local full_store_key
  full_store_key="$(_get_gopass_device_full_store_key_for "$repo" "$store_key")"
  gopass binary cat "$full_store_key"
}


cat_gopass_device_bin_secret() {
  _cat_gopass_device_bin_secret_from_repo "$(get_gopass_device_vault_id)" "$@"
}


cat_gopass_factory_only_device_bin_secret() {
  _cat_gopass_device_bin_secret_from_repo "$(get_gopass_factory_only_vault_id)" "$@"
}


delete_gopass_device_gpg_public_key_from_factory_keyring() {
  delete_device_gpg_public_key_from_factory_keyring
}


import_gopass_device_gpg_public_key_to_factory_keyring() {
  false
}


_deauthorize_gopass_device_from_device_private_substore_prim() {
  # local device_gpg_id_or_email="${1:-}"
  local device_gpg_key
  device_gpg_key="$(get_device_gpg_public_key_id)" || return 1

  local device_private_substore
  device_private_substore="$(get_gopass_device_substore_key)"

  # TODO: Improve: For the moment we have to do contorted / not robust matching on error as there are
  # no reliable way to check for authorized recipients.
  # if gopass recipients | grep -q "$device_gpg_key"; then

  local error_msg
  error_msg="$(2>&1 gopass --yes recipients deauthorize --store "$device_private_substore" "$device_gpg_key")"

  if echo "$error_msg" | grep -q "Starting rencrypt"; then
    echo "Secrets in substore '$device_private_substore' re-encryted so that '$device_gpg_key' no longer has access."
  elif ! echo "$error_msg" | grep -q "recipient not in store"; then
    1>&2 echo "ERROR: There was a problem deauthorizing '$device_gpg_key' as recipient to substore: '$device_private_substore'."
    1>&2 echo " -> $error_msg"
    return 1
  else
    echo "Nothing to do, '$device_gpg_key' already **not** authorized to '$device_private_substore'."
    # echo " -> $error_msg"
  fi
}


deauthorize_gopass_device_from_device_private_substore() {
  print_title_lvl3 "Deauthorize device from accessing its private sub-store"

  if has_device_gpg_public_key_id; then
    # Ensure any device key already in the factory keyring is
    # deauthorized and deleted from the keyring.
    print_title_lvl4 "Deauthorizing any device gpg key already in the factory user's keyring"
    _deauthorize_gopass_device_from_device_private_substore_prim || return 1
    delete_gopass_device_gpg_public_key_from_factory_keyring || return 1
  fi

  print_title_lvl4 "Deauthorizing device gpg key stored in the vault itself"

  if ! exists_gopass_factory_only_device_secret "$(get_rel_gpg_public_key_filename)"; then
    echo "No device gpg public public key stored. Nothing to do."
    return 0
  fi

  cat_gopass_factory_only_device_bin_secret "$(get_rel_gpg_public_key_filename)" \
    | import_gpg_public_key_from_stdin_to_factory_keyring || return 1

  _deauthorize_gopass_device_from_device_private_substore_prim || return 1
  delete_gopass_device_gpg_public_key_from_factory_keyring || return 1

  echo_eval 'gopass --yes recipients'
}


authorize_gopass_device_to_device_private_substore() {
  print_title_lvl3 "Authorize device access to its private sub-store"

  if ! exists_gopass_factory_only_device_secret "$(get_rel_gpg_public_key_filename)"; then
    1>&2 echo "ERROR: No device gpg public public key stored. Cannat proceed with device autorization."
    return 1
  fi

  cat_gopass_factory_only_device_bin_secret "$(get_rel_gpg_public_key_filename)" \
    | import_gpg_public_key_from_stdin_to_factory_keyring || return 1

  local device_gpg_key
  device_gpg_key="$(get_device_gpg_public_key_id)" || return 1

  local device_private_substore
  device_private_substore="$(get_gopass_device_substore_key)"
  # TODO: Improve: For the moment we have to do contorted / not robust matching on error as there are
  # no reliable way to check for authorized recipients.
  # if ! gopass recipients | grep -q "$device_gpg_key"; then

  local error_msg
  echo "$ gopass --yes recipients authorize --store '$device_private_substore' '$device_gpg_key'"
  error_msg="$(2>&1 gopass --yes recipients authorize --store "$device_private_substore" "$device_gpg_key")"

  if echo "$error_msg" | grep -q "Reencrypting existing secrets"; then
    echo "Secrets in substore '$device_private_substore' re-encryted for '$device_gpg_key'."
  elif ! echo "$error_msg" | grep -q "Recipient already in store"; then
    1>&2 echo "ERROR: There was a problem authorizing '$device_gpg_key' as recipient to substore: '$device_private_substore'."
    1>&2 echo " -> $error_msg"
    return 1
  else
    echo "Nothing to do, '$device_gpg_key' already authorized to '$device_private_substore'."
    # echo " -> $error_msg"
  fi

  echo_eval 'gopass --yes recipients'

  # TODO: Consider if we want the device key to be preserved in factory user's keyring.
  delete_gopass_device_gpg_public_key_from_factory_keyring || return 1
}
