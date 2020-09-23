#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/gpg.sh
. "$common_factory_install_sh_lib_dir/gpg.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_info_store.sh
. "$common_factory_install_sh_lib_dir/app_factory_info_store.sh"


run_factory_gpg() {
  run_sandboxed_gpg "$@"
}


run_factory_gpgconf() {
  run_sandboxed_gpgconf "$@"
}


run_factory_gpg_agent() {
  run_sandboxed_gpg_agent "$@"
}


list_factory_gpg_public_key_ids_w_email() {
  # Nothing as first argument defaults to current user home gpg dir.
  list_gpg_public_key_ids_w_email "" "${1:-}"
}


list_factory_gpg_public_key_ids() {
  # Nothing as first argument defaults to current user home gpg dir.
  list_gpg_public_key_ids "" "${1:-}"
}


list_factory_gpg_secret_key_ids_w_email() {
  # Nothing as first argument defaults to current user home gpg dir.
  list_gpg_secret_key_ids_w_email "" "${1:-}"
}


get_factory_gpg_id() {
  local factory_gpg_id_or_email
  factory_gpg_id_or_email="$(get_required_factory_info__user_gpg_default_id)" || return 1

  local key_list
  if ! key_list="$(list_factory_gpg_public_key_ids "$factory_gpg_id_or_email")"; then
    1>&2 echo "ERROR: get_factory_gpg_id_or_email: No gpg key found for '$factory_gpg_id_or_email'."
    return 1
  fi

  local key_count
  key_count="$(echo "$key_list" | wc -l)"

  if test "$key_count" -gt "1"; then
    local key_list_str
    key_list_str="$(echo "$key_list" | paste -s -d',')"
    1>&2 echo "ERROR: get_factory_gpg_id:"
    1>&2 echo "  Ambiguous gpg id for '$factory_gpg_id_or_email'. Found multiple ids: {$key_list_str}"
    1>&2 echo ""
    return 1
  fi

  local key
  key="$(echo "$key_list" | head -n 1)"
  echo "$key"
}


is_factory_gpg_id() {
  if ! [[ "x" == "${1:+x}" ]]; then
    1>&2 echo "ERROR: is_factory_gpg_id: missing argument".
    return 1
  fi

  local gpg_key_or_email="$1"


  local matching_key_list
  if ! matching_key_list="$(list_factory_gpg_public_key_ids "$gpg_key_or_email")"; then
    1>&2 echo "ERROR: is_factory_gpg_id: No gpg key found for '$gpg_key_or_email'."
    return 1
  fi

  local factory_gpg_id
  factory_gpg_id="$(get_factory_gpg_id)"
  echo "$matching_key_list" | grep -q "$factory_gpg_id"
}


delete_gpg_public_key_from_factory_keyring() {
  local gpg_key_or_email="$1"

  local key_w_email_list
  if ! key_w_email_list="$(list_factory_gpg_public_key_ids_w_email "$gpg_key_or_email")"; then
    1>&2 echo "WARNING: delete_gpg_public_key_from_factory_keyring: "
    1>&2 echo "  No public key found for '$gpg_key_or_email' in factory keyring."
    return 0
  fi

  local gpg_home_dir
  gpg_home_dir="$(get_default_gpg_home_dir)"

  echo "$key_w_email_list" | \
  while IFS=" " read -r key email; do
    if is_factory_gpg_id "$key"; then
      1>&2 echo "ERROR: delete_gpg_public_key_from_factory_keyring: "
      1>&2 echo "  attempting to delete factory's default public id"
      1>&2 echo "  with key: '$key' and email: '$email'. This is explicitly forbidden."
      return 1
    fi

    echo "Deleting gpg key: '$key' with email: '$email' from current factory user's keyring."
    echo_eval "GNUPGHOME='$gpg_home_dir' nix-gpg --batch --yes --delete-keys '$key'"
  done
}


import_gpg_public_key_file_to_factory_keyring() {
  local gpg_home_dir
  gpg_home_dir="$(get_default_gpg_home_dir)"

  local pub_key_filename="$1"
  echo "Importing gpg key from file '$pub_key_filename' into the factory user's keyring."
  echo_eval "GNUPGHOME='$gpg_home_dir' nix-gpg --batch --yes --import '$pub_key_filename'"
}


import_gpg_public_key_from_stdin_to_factory_keyring() {
  local gpg_home_dir
  gpg_home_dir="$(get_default_gpg_home_dir)"

  cat - | GNUPGHOME="$gpg_home_dir" nix-gpg --batch --yes --import -
}


import_gpg_public_key_to_factory_keyring() {
  local gpg_home_dir
  gpg_home_dir="$(get_default_gpg_home_dir)"

  local pub_key="$1"
  echo "Importing gpg key into the factory user's keyring."
  echo "echo \"\$pub_key\" | nix-gpg --batch --yes --import -"
  echo "$pub_key" | GNUPGHOME="$gpg_home_dir" nix-gpg --batch --yes --import
}


read_or_prompt_for_factory_user_gpg_default_id() {
  local -n _out_gpg_id="$1"
  _out_gpg_id=""

  local gpg_id_or_email
  read_or_prompt_for_factory_info__user_gpg_default_id "gpg_id_or_email"

  local matching_gpg_ids
  matching_gpg_ids="$(list_gpg_public_key_ids_w_email "" "" | grep "$gpg_id_or_email")"
  local matching_gpg_ids_count
  matching_gpg_ids_count="$(echo "$matching_gpg_ids" | wc -l)"
  if test "0" -eq "$matching_gpg_ids_count"; then
    1>&2 echo "ERROR: No keys found matching factory user default id '$gpg_id_or_email'."
    return 1
  fi

  if test "1" -lt "$matching_gpg_ids_count"; then
    matching_gpg_ids="$(list_gpg_secret_key_ids_w_email "" "" "" | grep "$gpg_id_or_email")"
    matching_gpg_ids_count="$(echo "$matching_gpg_ids" | wc -l)"
  fi


  if test "1" -lt "$matching_gpg_ids_count"; then
    1>&2 echo "ERROR: More that a single gpg id matching factory user default id '$gpg_id_or_email': '$matching_gpg_ids'."
    return 1
  fi

  # shellcheck disable=SC2034  # Out by ref.
  _out_gpg_id="$(echo "$matching_gpg_ids" | awk '{ printf $1 }' | head -n 1)"
}
