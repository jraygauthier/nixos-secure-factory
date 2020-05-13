#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/prompt.sh
. "$common_factory_install_sh_lib_dir/prompt.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/fields.sh
. "$common_factory_install_sh_lib_dir/fields.sh"

get_valid_git_email_from_config() {
  local user_email
  user_email="$(nix-git config --global --get user.email)" \
      && [[ -n "$user_email" ]] \
    || return 1

  echo "$user_email"
}


get_valid_git_name_from_config() {
  local user_name
  user_name="$(nix-git config --global --get user.name)" \
      && [[ -n "$user_name" ]] \
    || return 1

  echo "$user_name"
}


has_valid_git_email_from_config() {
  get_valid_git_email_from_config > /dev/null
}


has_valid_git_name_from_config() {
  get_valid_git_name_from_config > /dev/null
}


has_minimal_git_config() {
  has_valid_git_email_from_config \
    && has_valid_git_name_from_config
}


list_missing_git_config_fields() {
  local missing_config_fields=()
  if ! has_valid_git_email_from_config; then
    missing_config_fields+=( "user.email" )
  fi

  if ! has_valid_git_name_from_config; then
    missing_config_fields+=( "user.name" )
  fi

  if [[ "${#missing_config_fields[@]}" -eq 0 ]]; then
    return 1 # No missing fields (return false)
  fi

  printf "%s\n" "${missing_config_fields[@]}"
}


prompt_for_and_configure_git_user_email() {
  local _out_user_email_varname="${1?}"
  local _suggested_user_email="${2:-}"

  local _email_regexp
  _email_regexp="$(get_email_address_regexpr)"
  prompt_for_mandatory_parameter_loop "${_out_user_email_varname?}" \
    "git.user.email" "$_email_regexp" "$_suggested_user_email"
  nix-git config --global "user.email" "${!_out_user_email_varname}"
}


prompt_for_and_configure_git_user_name() {
    local _out_user_name_varname="${1?}"
    local _suggested_user_name="${2:-}"

    local _user_regexp
    _user_regexp="$(get_user_full_name_regexpr)"
    prompt_for_mandatory_parameter_loop "${_out_user_name_varname?}" \
      "git.user.name" "$_user_regexp" "$_suggested_user_name"
    nix-git config --global "user.name" "${!_out_user_name_varname}"
}


change_minimal_git_config() {
  local suggested_user_email
  suggested_user_email="$(get_valid_git_email_from_config || true)"
  local suggested_user_name
  suggested_user_name="$(get_valid_git_name_from_config || true)"

  local user_email
  prompt_for_and_configure_git_user_email "user_email" "$suggested_user_email"

  local user_name
  prompt_for_and_configure_git_user_name "user_name" "$suggested_user_name"
}


ensure_minimal_git_config_prompt_and_setup_if_not() {
  local suggested_user_email="${1:-}"
  local suggested_user_name="${2:-}"
  local treat_missing_fields_as_error="${3:-"true"}"
  if [[ "0" == "$treat_missing_fields_as_error" ]] \
      || [[ "false" == "$treat_missing_fields_as_error" ]]; then
    treat_missing_fields_as_error="false"
  elif [[ "true" != "$treat_missing_fields_as_error" ]]; then
    1>&2 echo "ensure_minimal_git_config_prompt_and_setup_if_not: Invalid parameter."
    return 1
  fi

  local missing_config_fields
  if ! missing_config_fields="$(list_missing_git_config_fields)"; then
    return 0 # Ok, already properly configured.
  fi

  local missing_field_str
  missing_field_str="{$(echo "$missing_config_fields" | paste -s -d',')}"

  if $treat_missing_fields_as_error; then
    1>&2 echo "ERROR: Git user configution is missing the following fields: '$missing_field_str'."
  else
    echo "Git user configution is missing the following fields: '$missing_field_str'."
  fi

  echo "We will prompt you for each missing field with a suggested value when available."

  if ! has_valid_git_email_from_config; then
    local user_email
    prompt_for_and_configure_git_user_email "user_email" "$suggested_user_email"
  fi

  if ! has_valid_git_name_from_config; then
    local user_name
    prompt_for_and_configure_git_user_name "user_name" "$suggested_user_name"
  fi
}


ensure_minimal_git_config_error_if_not() {
  if has_minimal_git_config; then
    return 0 # Ok, already set.
  fi

  1>&2 echo "ERROR: Git user configution is missing 'user.email' and/or 'user.name'. Fix by running: ''"
  1>&2 printf "git config --global user.email \"you@example.com\"\n"
  1>&2 printf "git config --global user.name \"Your Name\"\n''\n"
  return 1
}
