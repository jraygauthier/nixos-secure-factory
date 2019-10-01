#!/usr/bin/env bash
common_libexec_dir="$(pkg-nixos-common-get-libexec-dir)"
. "$common_libexec_dir/sh_stream.sh"

common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/prompt.sh"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/gopass.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"
. "$common_factory_install_libexec_dir/app_factory_gopass_vaults.sh"
. "$common_factory_install_libexec_dir/fields.sh"


run_factory_gopass_cli() {
  run_sandboxed_gopass "$@"
}


deauthorize_gpg_id_from_gopass_store() {
  local store_path="$1"
  local gpg_id="$2"

  # TODO: Improve: For the moment we have to do contorted / not robust matching on error as there are
  # no reliable way to check for authorized recipients.
  # if factory-gopass recipients | grep -q "$device_gpg_key"; then

  local error_msg
  local error_code=0
  echo "$ factory-gopass --yes recipients deauthorize --store '$store_path' '$gpg_id'"
  error_msg="$(2>&1 factory-gopass --yes recipients deauthorize --store "$store_path" "$gpg_id")" || \
    { error_code="$?"; }

  if [[ "0" -eq "$error_code" ]] && echo "$error_msg" | grep -q "Starting rencrypt"; then
    echo "Secrets in substore '$store_path' re-encryted to take into account that '$gpg_id' is now deauthorized."
    return 0
  elif [[ "17" -eq "$error_code" ]] && echo "$error_msg" | grep -q "recipient not in stor"; then
    echo "Nothing to do, '$gpg_id' was already **not** authorized to '$store_path'."
    # echo " -> $error_msg"
    return 0
  elif [[ "17" -eq "$error_code" ]] && echo "$error_msg" | grep -q "failed to commit changes to git: git has nothing to commit"; then
    echo "Nothing to do, '$gpg_id' already **not** authorized to '$store_path'."
    # echo " -> $error_msg"
    return 0
  elif ! [[ "0" -eq "$error_code" ]]; then
    1>&2 echo "ERROR('$error_code'): There was a problem deauthorizing '$gpg_id' as recipient to substore: '$store_path'."
    1>&2 echo " -> $error_msg"
    return 1
  fi

  echo "Success."
  echo " -> ${error_msg}"

  # TODO: Should not be treated as an error.
  # Error: failed to add recipient 'AF72B07CD39B7712AC472EB0FA282F683BDE3F7D': failed to commit changes to git: git has nothing to commit
}


authorize_gpg_id_to_gopass_store() {
  local store_path="$1"
  local gpg_id="$2"

  # TODO: Improve: For the moment we have to do contorted / not robust matching on error as there are
  # no reliable way to check for authorized recipients.
  # if factory-gopass recipients | grep -q "$device_gpg_key"; then

  local error_msg
  local error_code=0
  echo "$ factory-gopass --yes recipients authorize --store '$store_path' '$gpg_id'"
  error_msg="$(2>&1 factory-gopass --yes recipients authorize --store "$store_path" "$gpg_id")" || \
    { error_code="$?"; }

  if [[ "0" -eq "$error_code" ]] && echo "$error_msg" | grep -q "Reencrypting existing secrets"; then
    echo "Secrets in substore '$store_path' re-encryted for '$gpg_id'."
    return 0
  elif [[ "17" -eq "$error_code" ]] && echo "$error_msg" | grep -q "Recipient already in store"; then
    echo "Nothing to do, '$gpg_id' already authorized to '$store_path'."
    # echo " -> $error_msg"
    return 0
  elif [[ "17" -eq "$error_code" ]] && echo "$error_msg" | grep -q "failed to commit changes to git: git has nothing to commit"; then
    echo "Nothing to do, '$gpg_id' already authorized to '$store_path'."
    # echo " -> $error_msg"
    return 0
  elif ! [[ "0" -eq "$error_code" ]]; then
    1>&2 echo "ERROR('$error_code'): There was a problem authorizing '$gpg_id' as recipient to substore: '$store_path'."
    1>&2 echo " -> $error_msg"
    return 1
  fi

  echo "Success."
  echo " -> ${error_msg}"

  # TODO: Should not be treated as an error.
  # Error: failed to add recipient 'AF72B07CD39B7712AC472EB0FA282F683BDE3F7D': failed to commit changes to git: git has nothing to commit
}


deauthorize_factory_user_gpg_id_from_gopass_store() {
  local store_path="$1"
  local gpg_id_or_email="$2"

  # Note that we won't bother to check if we're working with a factory user id.
  # This is because we want to leave to possibility to deauthorize a device id
  # if it has
  local matching_gpg_id=""
  select_unique_gpg_id "matching_gpg_id" "$gpg_id_or_email" || return 1

  # Make sure we're not mistakenly trying to deauthorize ourself.
  if is_factory_gpg_id "$matching_gpg_id"; then
    1>&2 echo "ERROR: Trying to deauthorize factory user's gpg id from gopass store. Unsupported operation."
    return 1
  fi

  deauthorize_gpg_id_from_gopass_store "$store_path" "$matching_gpg_id"
}


authorize_factory_user_gpg_id_to_gopass_store() {
  local store_path="$1"
  local gpg_id_or_email="$2"

  # print_title_lvl2 "Authorizing '$gpg_id_or_email' to gopass store at '$store_path'"

  # Make sure we're not mistakenly trying to authorize a device to the store.
  local matching_gpg_id=""
  if ! select_unique_factory_user_gopass_gpg_id "matching_gpg_id" "$gpg_id_or_email"; then
    1>&2 printf "ERROR: Gpg id '%s' selected from '%s'\n" "$matching_gpg_id" "$gpg_id_or_email"
    1>&2 printf "  cannot be authorized to gopass store '%s'\n" "$store_path"
    1>&2 printf "  as not recognized as a valid factory user.\n"
    return 1
  fi

  authorize_gpg_id_to_gopass_store "$store_path" "$matching_gpg_id"
}


authorize_factory_user_peers_to_gopass_store() {
  local store_path="$1"

  local device_names
  device_names="$(list_all_device_names_from_gopass_factory_vaults_and_device_config)"

  while read -r gpg_id email; do
    echo "Authorizing factory user with gpg id '$gpg_id' and email '$email' to gopass store '$store_path'"
    # We do not whant a device to be inadvertantly authorized.
    if is_factory_user_gopass_gpg_id "$gpg_id" "$device_names"; then
      authorize_gpg_id_to_gopass_store "$store_path" "$gpg_id"
      echo "Ok."
    else
      1>&2 echo "WARNING: Skipped authorization of '$gpg_id'/'$email'. "
      1>&2 echo " -> Invalid factory user, most likely a device which shouldn't be authorized at this level."
    fi
  done < <(list_authorized_factory_user_peers_gpg_ids_w_email_from_gopass_vaults)
}



process_gpg_id_input_from_either_args_or_clipboard() {
  if [[ "x" == "${1:+x}" ]]; then
    local arg_input
    arg_input="$1"
    echo "$arg_input"
    return 0
  fi

  # TODO: Support stdin?

  local clipboard_input
  clipboard_input="$(DISPLAY="${DISPLAY:-":0"}" xclip -o -selection clipboard)"

  if [[ "" == "$clipboard_input" ]]; then
    1>&2 echo "ERROR: Empty clipboard."
    return 1
  fi

  local in_trimmed_first_line
  in_trimmed_first_line="$(echo "$clipboard_input" | head -n 1 | awk '{gsub(/^ +| +$/,"")} {print $0}')"

  if echo "$in_trimmed_first_line" | grep -q -E '^[A-F0-9]+$' \
      && [[ "41" -eq "${#in_trimmed_first_line}" ]]; then
    echo "$in_trimmed_first_line"
    return 0
  fi

  # Proper email character and single '@'.
  if echo "$in_trimmed_first_line" | grep -q -E '^[a-zA-Z0-9@\._-]+$' \
      && [[ "2" -eq "$(echo "$in_trimmed_first_line" | tr '@' '\n' | wc -l)" ]]; then
    echo "$in_trimmed_first_line"
    return 0
  fi


  local in_trimmed_last_line
  in_trimmed_last_line="$(echo "$clipboard_input" | tail -n 1 | awk '{gsub(/^ +| +$/,"")} {print $0}')"
  if echo "$in_trimmed_first_line" | grep -q -E '^-----BEGIN PGP PUBLIC KEY BLOCK-----$' \
      && echo "$in_trimmed_last_line" | grep -q '^-----END PGP PUBLIC KEY BLOCK-----$'; then

    local gpg_id_from_clipboard
    if ! gpg_id_from_clipboard="$(echo "$clipboard_input" | get_unique_gpg_id_from_armored_pub_key_stdin)"; then
      1>&2 echo "ERROR: No valid pgp data found in clipboard even though the public key header and footer where detected."
      return 1
    fi

    echo "$clipboard_input" | import_from_armored_pub_key_stdin \
      || return 1
    echo "$gpg_id_from_clipboard"
    return 0
  fi


  1>&2 echo "ERROR: Unrecognized data in clipboard. Cannot extract a gpg id from this."
  1>&2 printf "Here's the first 3 lines: ''\n%s\n''\n" "$(echo "$clipboard_input" | head -n 3)"
  return 1
}


_parse_factory_user_authorization_args() {
  local -n _out_gpg_id="${1?}"
  local -n _out_shallow="${2?}"
  shift 2
  _out_gpg_id=""
  _out_shallow=false

  local i

  while [ "$#" -gt 0 ]; do
      i="$1"; shift 1
      case "$i" in
        --shallow)
          # --shallow flag. Allow to deauthorize only from top level stores.
          _out_shallow=true
          ;;
        *)
          local gpg_id_or_email_regexp
          gpg_id_or_email_regexp="$(get_gpg_id_or_email_regexpr)" || return 1
          if ! echo "$i" | grep -E -q '^-' \
              && echo "$i" | grep -E -q "$gpg_id_or_email_regexp"; then
            _out_gpg_id="$i"
          else
            1>&2 echo "ERROR: $0: _parse_build_device_config_args: unknown option '$i'"
            return 1
          fi
          ;;
      esac
  done
}


deauthorize_factory_user_gpg_id_from_gopass_factory_vaults_cli() {
  print_title_lvl1 "Deauthorizing gpg id from gopass factory vaults"

  local gpg_id_or_email
  local shallow
  _parse_factory_user_authorization_args "gpg_id_or_email" "shallow" "$@"

  print_title_lvl2 "Importing missing gpg keys from the gopass vaults"
  if $shallow; then
    import_authorized_factory_user_peers_public_keys_from_gopass_vaults
  else
    import_all_authorized_peers_public_key_files_from_gopass_vaults
  fi

  print_title_lvl2 "Initializing and mounting gopass vaults"
  mount_factory_gopass_secrets_stores

  gpg_id_or_email="$(process_gpg_id_input_from_either_args_or_clipboard "$gpg_id_or_email")" || return 1
  echo "gpg_id_or_email='$gpg_id_or_email'"

  local matching_gpg_id=""
  select_unique_gpg_id "matching_gpg_id" "$gpg_id_or_email" || return 1

  local device_secrets_repo_key
  device_secrets_repo_key="$(get_gopass_device_vault_id)"
  local factory_secrets_repo_key
  factory_secrets_repo_key="$(get_gopass_factory_only_vault_id)"

  if ! $shallow; then
    print_title_lvl2 "Deauthorizing the user from per device substores"

    while read -r dn; do
      echo "$dn"
      mount_gopass_factory_device_substores "$dn" || return 1
      local device_substore_key
      device_substore_key="$(get_gopass_device_substore_key "$dn")" || return 1
      local device_factory_only_substore
      device_factory_only_substore="$(get_gopass_device_factory_only_substore_key "$dn")" || return 1

      deauthorize_gpg_id_from_gopass_store "$device_substore_key" "$matching_gpg_id" || return 1
      deauthorize_gpg_id_from_gopass_store "$device_factory_only_substore" "$matching_gpg_id" || return 1
    done < <(list_all_device_names_from_gopass_device_secret_vault)
  fi

  print_title_lvl2 "Deauthorizing the user from top level gopass vaults"

  deauthorize_factory_user_gpg_id_from_gopass_store "$factory_secrets_repo_key" "$matching_gpg_id"
  deauthorize_factory_user_gpg_id_from_gopass_store "$device_secrets_repo_key" "$matching_gpg_id"

  print_title_lvl2 "Printing recipients summary"
  echo_eval "factory-gopass --yes recipients"
}


authorize_factory_user_gpg_id_to_gopass_factory_vaults_cli() {
  print_title_lvl1 "Authorizing factory user gpg id to gopass factory vaults"

  local gpg_id_or_email
  local shallow
  _parse_factory_user_authorization_args "gpg_id_or_email" "shallow" "$@"

  print_title_lvl2 "Importing missing gpg keys from the gopass vaults"
  if $shallow; then
    import_authorized_factory_user_peers_public_keys_from_gopass_vaults
  else
    import_all_authorized_peers_public_key_files_from_gopass_vaults
  fi

  print_title_lvl2 "Initializing and mounting gopass vaults"
  mount_factory_gopass_secrets_stores


  print_title_lvl2 "Identifying unique gpg id from user input"

  gpg_id_or_email="$(process_gpg_id_input_from_either_args_or_clipboard "$gpg_id_or_email")" || return 1
  echo "gpg_id_or_email='$gpg_id_or_email'"

  local matching_gpg_id=""
  select_unique_gpg_id "matching_gpg_id" "$gpg_id_or_email" || return 1

  local device_secrets_repo_key
  device_secrets_repo_key="$(get_gopass_device_vault_id)"
  local factory_secrets_repo_key
  factory_secrets_repo_key="$(get_gopass_factory_only_vault_id)"

  print_title_lvl2 "Authorizing the user to gopass vaults"

  authorize_factory_user_gpg_id_to_gopass_store "$factory_secrets_repo_key" "$matching_gpg_id"
  authorize_factory_user_gpg_id_to_gopass_store "$device_secrets_repo_key" "$matching_gpg_id"

  if ! $shallow; then
    print_title_lvl2 "Authorizing the user to per device substores"

    while read -r dn; do
      echo "$dn"
      mount_gopass_factory_device_substores "$dn" || return 1
      local device_substore_key
      device_substore_key="$(get_gopass_device_substore_key "$dn")" || return 1
      local device_factory_only_substore
      device_factory_only_substore="$(get_gopass_device_factory_only_substore_key "$dn")" || return 1

      authorize_gpg_id_to_gopass_store "$device_substore_key" "$matching_gpg_id" || return 1
      authorize_gpg_id_to_gopass_store "$device_factory_only_substore" "$matching_gpg_id" || return 1
    done < <(list_all_device_names_from_gopass_device_secret_vault)
  fi

  print_title_lvl2 "Printing recipients summary"
  echo_eval "factory-gopass --yes recipients"
}


list_factory_gopass_vaults_recipients() {
  factory-gopass --yes recipients
}
