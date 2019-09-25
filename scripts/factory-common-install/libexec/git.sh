#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/prompt.sh"


ensure_minimal_git_config_prompt_and_setup_if_not() {
  local missing_config_fields=()

  local user_email
  if ! user_email="$(nix-git config --global --get user.email)" \
      || [[ -z "$user_email" ]]; then
    missing_config_fields+=( 'user.email' )
  fi

  local user_name
  if ! user_name="$(nix-git config --global --get user.name)" \
      || [[ -z "$user_name" ]]; then
    missing_config_fields+=( 'user.name' )
  fi

  if [[ "${#missing_config_fields[@]}" -eq 0 ]]; then
    return 0 # Ok, already set.
  fi

  local missing_field_str
  missing_field_str="{$(printf "%s\n" "${missing_config_fields[@]}" | paste -s -d',')}"

  1>&2 echo "ERROR: Git user configution is missing '$missing_field_str'."
  1>&2 echo "Enter it here and we will configure git for you:"

  if [[ -z "$user_email" ]]; then
    local email_regexp
    email_regexp="$(get_email_address_regexpr)"
    prompt_for_mandatory_parameter_loop "user_email" "git.user.email" "$email_regexp"
    nix-git config --global user.email "$user_email"
  fi

  if [[ -z "$user_name" ]]; then
    local user_regexp
    user_regexp="$(get_user_full_name_regexpr)"
    prompt_for_mandatory_parameter_loop "user_name" "git.user.name" "$user_regexp"
    nix-git config --global user.name "$user_name"
  fi
}


ensure_minimal_git_config_error_if_not() {
  local user_email
  local user_name
  if user_email="$(nix-git config --global --get user.email)" \
      && [[ -n "$user_email" ]] \
      && user_name="$(nix-git config --global --get user.name)" \
      && [[ -n "$user_name" ]]; then
    return 0 # Ok, already set.
  fi

  1>&2 echo "ERROR: Git user configution is missing 'user.email' and/or 'user.name'. Fix by running: ''"
  1>&2 printf "git config --global user.email \"you@example.com\"\n"
  1>&2 printf "git config --global user.name \"Your Name\"\n''\n"
  return 1
}