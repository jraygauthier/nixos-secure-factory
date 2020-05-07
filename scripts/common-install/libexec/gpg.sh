#!/usr/bin/env bash
common_libexec_dir="$(pkg-nixos-sf-common-get-libexec-dir)"
. "$common_libexec_dir"/permissions.sh
. "$common_libexec_dir"/sh_stream.sh
# common_install_libexec_dir="$(pkg-nixos-sf-common-install-get-libexec-dir)"


wipe_gpg_home_dir() {
  printf -- "\n"
  printf -- "Wiping gpg home dir\n"
  printf -- "-------------------\n\n"

  local target_gpg_home_dir="$1"
  echo "rm -fr '$target_gpg_home_dir'"
  rm -fr "$target_gpg_home_dir"
}


create_and_assign_proper_permissions_to_gpg_home_dir_lazy_and_silent() {
  local target_gpg_home_dir="$1"

  local gpg_home_dir_newly_created=true
  test -d "$target_gpg_home_dir" || gpg_home_dir_newly_created=false
  create_and_assign_proper_permissions_to_dir_lazy "$target_gpg_home_dir" "700"
  create_and_assign_proper_permissions_to_dir_lazy "$target_gpg_home_dir/private-keys-v1.d" "700"

  if $gpg_home_dir_newly_created; then
    # Force automated creation of missing files.
    nix-gpg --homedir "$target_gpg_home_dir" --list-keys > /dev/null
  fi
}


create_and_assign_proper_permissions_to_gpg_home_dir() {
  printf -- "\n"
  printf -- "Creating fresh gpg homedir or assigning proper permission to existing.\n"
  printf -- "----------------------------------------------------------------------\n\n"

  local target_gpg_home_dir="$1"

  if test -d "$target_gpg_home_dir"; then
    # Ensure all required directories exists and have proper permissions.
    echo "Updating permission in existing gpghome at: '$target_gpg_home_dir'."
    chmod 700 "$target_gpg_home_dir"
    mkdir -p "$target_gpg_home_dir/private-keys-v1.d"
    chmod 700 "$target_gpg_home_dir/private-keys-v1.d"
  else
    echo "Creating initial gpghome at: '$target_gpg_home_dir'."
    mkdir -m 700 -p "$target_gpg_home_dir"
    mkdir -m 700 -p "$target_gpg_home_dir/private-keys-v1.d"
    # Force automated creation of missing files.
    nix-gpg --homedir "$target_gpg_home_dir" --list-keys
  fi
}


import_gpg_subkeys() {
  printf -- "\n"
  printf -- "Importing gpg subkeys to target gpg home\n"
  printf -- "----------------------------------------\n\n"

  local target_gpg_home_dir="$1"
  local exported_subkeys_file="$2"
  local exported_otrust_file="$3"
  local passphrase="${4:-}"

  create_and_assign_proper_permissions_to_gpg_home_dir "$target_gpg_home_dir"

  # --passphrase "$passphrase"
  # echo "$passphrase" | nix-gpg --homedir "$target_gpg_home_dir" \
  #   --batch  --pinentry-mode loopback --yes --no-tty --passphrase-fd 0  \
  #   --import "$exported_subkeys_file"

  echo "Importing subkeys from '$exported_subkeys_file'."
  nix-gpg --homedir "$target_gpg_home_dir" \
    --batch  --passphrase "$passphrase" \
    --import "$exported_subkeys_file"

  echo "Importing owner trust from '$exported_otrust_file'."
  nix-gpg --homedir "$target_gpg_home_dir" < "$exported_otrust_file" \
    --import-ownertrust

  echo "Keys after --import subkeys:"
  nix-gpg --homedir "$target_gpg_home_dir" --list-secret-keys
}


get_gpg_keyring_location_generic() {
  local gpg_exe="$1"
  shift 1
  "$gpg_exe" "$@" --version | grep -E '^Home:' | awk -F':' '{ print $2 }' | awk '{gsub(/^ +| +$/,"")} { print $0 }'
}



get_email_for_gpg_id_generic() {
  local gpg_exe="$1"
  local gpg_id_or_email="$2"
  shift 2

  local gpg_keys_w_email="$("$gpg_exe" "$@" --list-options show-only-fpr-mbox --list-public-keys)"

  local found_gpg_ids_w_emails
  if ! found_gpg_ids_w_emails="$(echo "$gpg_keys_w_email" | grep -E "$gpg_id_or_email")"; then
    local keyring_path
    keyring_path="$(get_gpg_keyring_location_generic "$gpg_exe", "${_gpg_args_a[@]}")"
    1>&2 echo "ERROR: No gpg id found for '$gpg_id_or_email' in keyring '$keyring_path'."
    return 1
  fi

  if ! is_mem_sh_stream_singleton "$found_gpg_ids_w_emails"; then
    local keyring_path
    keyring_path="$(get_gpg_keyring_location_generic "$gpg_exe" "${_gpg_args_a[@]}")"
    1>&2 echo "ERROR: Multiple matching emails for '$gpg_id_or_email' found in '$keyring_path'."
    1>&2 printf "Matching entries were: ''\n%s\n''\n" "$found_gpg_ids_w_emails"
    return 1
  fi

  local found_email="$(echo "$found_gpg_ids_w_emails" | head -n 1 | awk '{ print $2 }')"
  echo "$found_email"
}


select_unique_gpg_key_in_keyring() {
  local -n _out_ref="$1"
  local gpg_exe="$2"
  local _gpg_args_a_varname="$3"
  local -n _gpg_args_a="$_gpg_args_a_varname"
  local key_type="$4"
  local gpg_id_or_email="${5:-}"

  _out_ref=""

  local all_keys_of_type="$(\
    "$gpg_exe" "${_gpg_args_a[@]}" \
      --list-options show-only-fpr-mbox --list-${key_type}-keys)"

  local matched_keys="$all_keys_of_type"
  if [[ -n "$gpg_id_or_email" ]]; then
    matched_keys="$(echo "$all_keys_of_type" | grep "$gpg_id_or_email")" || true
  fi

  if is_mem_sh_stream_empty "$matched_keys"; then
    local keyring_path
    keyring_path="$(get_gpg_keyring_location_generic "$gpg_exe" "${_gpg_args_a[@]}")"
    1>&2 echo "ERROR: No such ${key_type} gpg key found in gpg keyring '$keyring_path' matching for '$gpg_id_or_email'."
    1>&2 printf "Available ${key_type} keys in the keyring are: ''\n%s\n''\n" "$all_keys_of_type"
    return 1
  fi

  if ! is_mem_sh_stream_singleton "$matched_keys"; then
    local keyring_path
    keyring_path="$(get_gpg_keyring_location_generic "$gpg_exe" "${_gpg_args_a[@]}")"
    1>&2 echo "ERROR: Multiple matching ${key_type} gpg keys for '$gpg_id_or_email' found in '$keyring_path'."
    1>&2 printf "Matched ${key_type} gpg keys were: ''\n%s\n''\n" "$matched_keys"
    return 1
  fi

  _out_ref="$(echo "$matched_keys" | head -n 1 | awk '{ printf $1 }')"
  # echo "matched_key='$matched_key'"
}


transfer_gpg_secret_and_public_keys_from_keyring_to_keyring() {
  local source_gpg_exe="$1"
  local -n _source_gpg_args_a="$2"
  local target_gpg_exe="$3"
  local -n _target_gpg_args_a="$4"
  local gpg_id_or_email="${5:-}"

  local key_type="secret"
  local matched_key=""
  select_unique_gpg_key_in_keyring "matched_key" "$source_gpg_exe" "$2" "$key_type" "$gpg_id_or_email" \
    || return 1
  # echo "matched_key='$matched_key'"

  "$source_gpg_exe" "${_source_gpg_args_a[@]}" --export-secret-keys --armor "$matched_key" | \
    "$target_gpg_exe" "${_target_gpg_args_a[@]}" --import - || return 1
  "$source_gpg_exe" "${_source_gpg_args_a[@]}" --export --armor "$matched_key" | \
    "$target_gpg_exe" "${_target_gpg_args_a[@]}" --import - || return 1
  "$source_gpg_exe" "${_source_gpg_args_a[@]}" --export-ownertrust | grep -E -e '^#' -e "^${matched_key}" | \
    "$target_gpg_exe" "${_target_gpg_args_a[@]}" --import-ownertrust - || return 1
}


transfer_gpg_public_key_from_keyring_to_keyring() {
  local source_gpg_exe="$1"
  local -n _source_gpg_args_a="$2"
  local target_gpg_exe="$3"
  local -n _target_gpg_args_a="$4"
  local gpg_id_or_email="${5:-}"


  local key_type="public"
  local matched_key=""
  select_unique_gpg_key_in_keyring "matched_key" "$source_gpg_exe" "$2" "$key_type" "$gpg_id_or_email" \
    || return 1
  # echo "matched_key='$matched_key'"

  # TODO: decide whether to move owner trust too. Won't that require a password?
  "$source_gpg_exe" "${_source_gpg_args_a[@]}" --export --armor "$matched_key" | \
    "$target_gpg_exe" "${_target_gpg_args_a[@]}" --import - || return 1
  "$source_gpg_exe" "${_source_gpg_args_a[@]}" --export-ownertrust | grep -E -e '^#' -e "^${matched_key}" | \
    "$target_gpg_exe" "${_target_gpg_args_a[@]}" --import-ownertrust - || return 1
}
