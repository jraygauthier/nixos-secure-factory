#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"


list_factory_gpg_public_key_ids_w_email() {
  # Nothing as first argument defaults to current user home gpg dir.
  list_gpg_public_key_ids_w_email "" "$1"
}


list_factory_gpg_public_key_ids() {
  # Nothing as first argument defaults to current user home gpg dir.
  list_gpg_public_key_ids "" "$1"
}


is_factory_gpg_default_id() {
  local gpg_key_or_email="$1"
  echo "$gpg_key_or_email" | grep -q "$(get_required_factory_info__user_gpg_default_id)"
}


delete_gpg_public_key_from_factory_keyring() {
  local gpg_key_or_email="$1"

  local key_w_email_list
  if ! key_w_email_list="$(list_factory_gpg_public_key_ids_w_email "$gpg_key_or_email")"; then
    1>&2 echo "WARNING: delete_gpg_public_key_from_factory_keyring: "
    1>&2 echo "  No public key found for '$gpg_key_or_email' in factory keyring."
    return 0
  fi

  echo "$key_w_email_list" | \
  while IFS=" " read -r key email; do
    if is_factory_gpg_default_id "$key" || is_factory_gpg_default_id "$email"; then
      1>&2 echo "ERROR: delete_gpg_public_key_from_factory_keyring: "
      1>&2 echo "  attempting to delete factory's default public id"
      1>&2 echo "  with key: '$key' and email: '$email'. This is explicitly forbidden."
      return 1
    fi

    echo "Deleting gpg key: '$key' with email: '$email' from current factory user's keyring."
    echo_eval "gpg --batch --yes --delete-keys '$key'"
  done
}


import_gpg_public_key_file_to_factory_keyring() {
  local pub_key_filename="$1"
  echo "Importing gpg key from file '$pub_key_filename' into the factory user's keyring."
  echo_eval "gpg --batch --yes --import '$pub_key_filename'"
}


import_gpg_public_key_from_stdin_to_factory_keyring() {
  cat - | gpg --batch --yes --import -
}


import_gpg_public_key_to_factory_keyring() {
  local pub_key="$1"
  echo "Importing gpg key into the factory user's keyring."
  echo "echo \"\$pub_key\" | gpg --batch --yes --import -"
  echo "$pub_key" | gpg --batch --yes --import
}
