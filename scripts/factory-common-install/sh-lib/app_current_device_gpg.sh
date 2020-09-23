#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/gpg.sh
. "$common_factory_install_sh_lib_dir/gpg.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_gpg.sh
. "$common_factory_install_sh_lib_dir/app_factory_gpg.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_gopass.sh
. "$common_factory_install_sh_lib_dir/app_factory_gopass.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"


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

