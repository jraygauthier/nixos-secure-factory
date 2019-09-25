#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"



_LATIN_ACCENTED_CHARS="àäçéèëïìÀÄÇÉÈËÏÌ"


get_latin_accented_chars() {
  echo "$_LATIN_ACCENTED_CHARS"
}



prompt_for_user_approval() {
  read -p "Continue (y/n)? " -n 1 -r
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
  local out_var_name="$1"
  local prompt_str="${2:-Enter passphrase (empty for no passphrase): }"

  read -p "$prompt_str" -s "password"
  printf -- "\n"

  # TODO: Validate using 'cracklib''s 'cracklib-check' which however currently
  # fails with: "pw_dict.pwd.gz: No such file or directory"
  # on nixos 19.03.

  eval "${out_var_name}=\"${password}\""
}


prompt_for_passphrase_impl() {
  local out_var_name="$1"
  local prompt_str="${2:-Enter passphrase (empty for no passphrase): }"
  local repeat_prompt_str="${3:-Enter same passphrase again: }"
  local not_match_error_str="${4:-Passphrases do not match. Try again.}"

  prompt_for_passphrase_no_repeat_impl "to_be_confirmed_pw" "$prompt_str"
  prompt_for_passphrase_no_repeat_impl "repeated_pw" "$repeat_prompt_str"

  if test "$to_be_confirmed_pw" != "$repeated_pw"; then
    1>&2 echo "$not_match_error_str"
    return 1
  fi

  eval "${out_var_name}=\"${repeated_pw}\""
}


prompt_for_passphrase() {
  local not_match_error_str="${4:-Passphrases do not match. Please try again later. Exiting.}"
  if ! prompt_for_passphrase_impl "$1" "${2:-}" "${3:-}" "$not_match_error_str"; then
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
  local out_var_name="$1"
  shift 1

  local out_file="$(mktemp)"
  rm_out_file() {
    # echo "rm_out_file: $out_file"
    rm -f "$out_file"
  }
  trap "{ rm_out_file; }" EXIT

  local libexec_dir
  libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
  $libexec_dir/prompt_for_custom_choices_readline -of "$out_file" "$@"
  return_code="$?"
  # echo "return_code1=$return_code"

  if ! test "0" -eq "$return_code"; then
    if test "$return_code" -gt "1"; then
      current_proc_id=$$
      # echo "current_proc_id=$current_proc_id"
      printf "^C"
      kill -INT $current_proc_id
    fi
    return $return_code
  fi
  local out="$(cat "$out_file")"
  echo "out=$out"
  trap - EXIT
  rm_out_file

  eval "${out_var_name}=\"${out}\""
}


prompt_for_custom_choices_strict() {
  local out_var_name="$1"
  local prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$out_var_name" -p "$prompt_str" --strict -r 1 -dc "$@" || exit
}


prompt_for_custom_choices_strict_loop() {
  local out_var_name="$1"
  local prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$out_var_name" -p "$prompt_str" --strict -r 0 -dc "$@" || exit
}


prompt_for_custom_choices() {
  local out_var_name="$1"
  local prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$out_var_name" -p "$prompt_str" -r 1 -dc "$@" || exit
}


prompt_for_custom_choices_loop() {
  local out_var_name="$1"
  local prompt_str="$2"
  shift 2
  _prompt_for_custom_choices_impl "$out_var_name" -p "$prompt_str" -r 0 -dc "$@" || exit
}


prompt_for_mandatory_parameter_impl() {
  local out_var_name="$1"
  local param="$2"
  local default_value_re="^[a-zA-Z0-9_\.]+$"
  local value_re=${3:-"$default_value_re"}

  read -p "$param: " $out_var_name
  local value="$(eval echo \$$out_var_name)"
  if ! echo "$value" | grep -Eq "$value_re"; then
    1>&2 echo "ERROR: Variable \`$param\`'s value of \`$value\` is not allowed to contain characters not in the set: \`$value_re\`."
    return 1
  fi
}


prompt_for_mandatory_parameter() {
  if ! prompt_for_mandatory_parameter_impl "$1" "$2" "${3:-}"; then
    exit 1
  fi
}


prompt_for_mandatory_parameter_loop() {
  while ! prompt_for_mandatory_parameter_impl "$1" "$2" "${3:-}"; do
    true
  done
}


prompt_for_optional_parameter_impl() {
  local out_var_name="$1"
  local param="$2"
  local default_value_re="^[a-zA-Z0-9_\.]*$"
  local value_re=${3:-"$default_value_re"}
  echo -n "$param: "
  read $out_var_name
  local value="$(eval echo \$$out_var_name)"
  if ! echo "$value" | grep -Eq "$value_re"; then
    1>&2 echo "ERROR: Variable \`$param\`'s value of \`$value\` is not allowed to contain characters not in the set: \`$value_re\`."
    return 1
  fi
}


prompt_for_optional_parameter() {
  if ! prompt_for_optional_parameter_impl "$1" "$2" "${3:-}"; then
    exit 1
  fi
}



prompt_for_optional_parameter_loop() {
  while ! prompt_for_optional_parameter_impl "$1" "$2" "${3:-}"; do
    true
  done
}

get_user_full_name_regexpr() {
  # local value_re="^[a-zA-Z0-9\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s_]+$"
  # TODO: Review this if at some point non latin alphabets are required.
  echo "^[a-zA-Z0-9$(get_latin_accented_chars)_ -]+$"
}

get_email_address_regexpr() {
  echo "^[a-zA-Z0-9@\.$(get_latin_accented_chars)_-]+$"
}
