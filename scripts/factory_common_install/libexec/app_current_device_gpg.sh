#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/app_factory_gpg.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"


delete_device_gpg_public_key_from_factory_keyring() {
  local device_email
  device_email="$(get_required_current_device_email)"

  delete_gpg_public_key_from_factory_keyring "$device_email"
}


has_device_gpg_public_key_id() {
  local device_email
  device_email="$(get_required_current_device_email)"
  list_factory_gpg_public_key_ids "$device_email" > /dev/null
}


get_device_gpg_public_key_id() {
  local device_email
  device_email="$(get_required_current_device_email)"

  local key_list
  if ! key_list="$(list_factory_gpg_public_key_ids "$device_email")"; then
    1>&2 echo "ERROR: get_device_gpg_public_key_id: No gpg key found for '$device_email'."
    return 1
  fi

  local key_count
  key_count="$(echo "$key_list" | wc -l)"

  if test "$key_count" -gt "1"; then
    local key_list_str
    key_list_str="$(echo "$key_list" | paste -s -d',')"
    1>&2 echo "ERROR: get_device_gpg_public_key_id:"
    1>&2 echo "  Ambiguous gpg id for '$device_email'. Found multiple ids: {$key_list_str}"
    1>&2 echo ""
    return 1
  fi

  local key
  key="$(echo "$key_list" | head -n 1)"
  echo "$key"
}
