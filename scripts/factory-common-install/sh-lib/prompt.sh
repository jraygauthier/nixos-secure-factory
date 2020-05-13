#!/usr/bin/env bash

prompt_for_user_approval() {
  local prompt="${1:-Continue}"

  read -p "${prompt} (y/n)? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    true
  elif [[ $REPLY =~ ^[Nn]$ ]]; then
    false
  else
    false
  fi
}


prompt_for_passphrase_no_repeat_impl() {
  local _out_var_name="$1"
  local _prompt_str="${2:-Enter passphrase (empty for no passphrase): }"

  read -r -p "$_prompt_str" -s "password"
  printf -- "\n"

  # TODO: Validate using 'cracklib''s 'cracklib-check' which however currently
  # fails with: "pw_dict.pwd.gz: No such file or directory"
  # on nixos 19.03.

  eval "${_out_var_name}=\"${password}\""
}


prompt_for_passphrase_impl() {
  local _out_var_name="$1"
  local _prompt_str="${2:-Enter passphrase (empty for no passphrase): }"
  local _repeat_prompt_str="${3:-Enter same passphrase again: }"
  local _not_match_error_str="${4:-Passphrases do not match. Try again.}"

  prompt_for_passphrase_no_repeat_impl "to_be_confirmed_pw" "$_prompt_str"
  prompt_for_passphrase_no_repeat_impl "repeated_pw" "$_repeat_prompt_str"

  if test "$to_be_confirmed_pw" != "$repeated_pw"; then
    1>&2 echo "$_not_match_error_str"
    return 1
  fi

  eval "${_out_var_name}=\"${repeated_pw}\""
}


prompt_for_passphrase() {
  local _not_match_error_str="${4:-Passphrases do not match. Please try again later. Exiting.}"
  if ! prompt_for_passphrase_impl "$1" "${2:-}" "${3:-}" "$_not_match_error_str"; then
    exit 1
  fi
}


prompt_for_passphrase_loop() {
  while ! prompt_for_passphrase_impl "$1" "${2:-}" "${3:-}" "${4:-}"; do
    true
  done
}


prompt_for_passphrase_no_repeat() {
  if ! prompt_for_passphrase_no_repeat_impl "$1" "${2:-}"; then
    exit 1
  fi
}


prompt_for_passphrase_no_repeat_loop() {
  while ! prompt_for_passphrase_no_repeat_impl "$1" "${2:-}"; do
    true
  done
}


_prompt_for_custom_choices_impl() {
  local -n _out_var_ref="$1"
  shift 1

  local _out_file="$(mktemp)"
  rm_out_file() {
    # echo "rm_out_file: $_out_file"
    rm -f "$_out_file"
  }
  trap "{ rm_out_file; }" EXIT

  local _sh_lib_dir
  _sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
  "$_sh_lib_dir/prompt_for_custom_choices_readline" -of "$_out_file" "$@"
  _return_code="$?"
  # echo "return_code1=$_return_code"

  if ! test "0" -eq "$_return_code"; then
    if test "$_return_code" -gt "1"; then
      _current_proc_id=$$
      # echo "_current_proc_id=$_current_proc_id"
      printf "^C"
      kill -INT $_current_proc_id
    fi
    return $_return_code
  fi
  _out_var_ref="$(cat "$_out_file")"
  # echo "out=$_out_var_ref"
  trap - EXIT
  rm_out_file
}


prompt_for_custom_choices_strict() {
  local _out_var_name="$1"
  local _prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$_out_var_name" -p "$_prompt_str" --strict -r 1 -dc "$@" || exit
}


prompt_for_custom_choices_strict_loop() {
  local _out_var_name="$1"
  local _prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$_out_var_name" -p "$_prompt_str" --strict -r 0 -dc "$@" || exit
}


prompt_for_custom_choices() {
  local _out_var_name="$1"
  local _prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$_out_var_name" -p "$_prompt_str" -r 1 -dc "$@" || exit
}


prompt_for_custom_choices_loop() {
  local _out_var_name="$1"
  local _prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$_out_var_name" -p "$_prompt_str" -r 0 -dc "$@" || exit
}


prompt_for_mandatory_parameter_impl() {
  local _out_var_name="$1"
  local _param="$2"
  local _default_value_re="^[a-zA-Z0-9_\.]+$"
  local _value_re=${3:-"$_default_value_re"}
  local _default_value="${4:-}"

  # echo "_default_value='$_default_value'"

  read -e -r -p "${_param}: " -i "$_default_value" "${_out_var_name?}"
  if ! echo "${!_out_var_name}" | grep -Eq "$_value_re"; then
    1>&2 echo "ERROR: Variable '$_param''s value of '${!_out_var_name}' is not allowed to contain characters not in the set: '$_value_re'."
    return 1
  fi
}


prompt_for_mandatory_parameter() {
  if ! prompt_for_mandatory_parameter_impl "$@"; then
    exit 1
  fi
}


prompt_for_mandatory_parameter_loop() {
  while ! prompt_for_mandatory_parameter_impl "$@"; do
    true
  done
}


prompt_for_optional_parameter_impl() {
  local _out_var_name="$1"
  local _param="$2"
  local _default_value_re="^[a-zA-Z0-9_\.]*$"
  local _value_re=${3:-"$_default_value_re"}
  local _default_value="${4:-}"
  read -e -r -p "${_param}: " -i "$_default_value" "${_out_var_name?}"
  if ! echo "${!_out_var_name}" | grep -Eq "$_value_re"; then
    1>&2 echo "ERROR: Variable '$_param''s value of '${!_out_var_name}' is not allowed to contain characters not in the set: '$_value_re'."
    return 1
  fi
}


prompt_for_optional_parameter() {
  if ! prompt_for_optional_parameter_impl "$@"; then
    exit 1
  fi
}


prompt_for_optional_parameter_loop() {
  while ! prompt_for_optional_parameter_impl "$@"; do
    true
  done
}
