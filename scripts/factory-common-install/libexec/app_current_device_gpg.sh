#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/app_factory_gpg.sh"
. "$common_factory_install_libexec_dir/app_factory_gopass.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"


has_device_gpg_id() {
  has_current_device_gpg_id
}


get_device_gpg_id_or_email() {
  local device_gpg_id_or_email
  device_gpg_id_or_email="$(get_current_device_gpg_id_or_email)" || return 1

  local key_list
  if ! key_list="$(list_factory_gpg_public_key_ids "$device_gpg_id_or_email")"; then
    1>&2 echo "ERROR: get_device_gpg_id_or_email: No gpg key found for '$device_gpg_id_or_email'."
    return 1
  fi

  local key_count
  key_count="$(echo "$key_list" | wc -l)"

  if test "$key_count" -gt "1"; then
    local key_list_str
    key_list_str="$(echo "$key_list" | paste -s -d',')"
    1>&2 echo "ERROR: get_device_gpg_id_or_email:"
    1>&2 echo "  Ambiguous gpg id for '$device_gpg_id_or_email'. Found multiple ids: {$key_list_str}"
    1>&2 echo ""
    return 1
  fi

  local key
  key="$(echo "$key_list" | head -n 1)"
  echo "$key"
}


get_device_gpg_id() {
  local device_gpg_id
  device_gpg_id="$(get_current_device_gpg_id)" || return 1

  local key_list
  if ! key_list="$(list_factory_gpg_public_key_ids "$device_gpg_id")"; then
    1>&2 echo "ERROR: get_device_gpg_id: No gpg key found for '$device_gpg_id'."
    return 1
  fi

  local key_count
  key_count="$(echo "$key_list" | wc -l)"

  if test "$key_count" -gt "1"; then
    local key_list_str
    key_list_str="$(echo "$key_list" | paste -s -d',')"
    1>&2 echo "ERROR: get_device_gpg_id:"
    1>&2 echo "  Ambiguous gpg id for '$device_gpg_id'. Found multiple ids: {$key_list_str}"
    1>&2 echo ""
    return 1
  fi

  local key
  key="$(echo "$key_list" | head -n 1)"
  echo "$key"
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

      store_current_device_gpg_id "$gpg_id_from_pub_key" || return 1
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
