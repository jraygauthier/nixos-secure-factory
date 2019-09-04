#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
# Source both dependencies.
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/prompt.sh"




get_factory_info_store_yaml_filename() {
  factory_install_repo_root_dir="$(get_factory_install_repo_root_dir)"
  echo "$factory_install_repo_root_dir/.factory-info.yaml"
}


is_factory_info_specified() {
  local store_yaml
  store_yaml="$(get_factory_info_store_yaml_filename)"
  test -f "$store_yaml"
}


ensure_factory_info_specified() {
  local store_yaml
  store_yaml="$(get_factory_info_store_yaml_filename)"
  local store_yaml_basename="$(basename "$store_yaml")"
  local store_yaml_dirname="$(dirname "$store_yaml")"
  is_factory_info_specified || \
    { 1>&2 echo "ERROR: '$store_yaml_basename' file does not exists in '$store_yaml_dirname'."; exit 1; }
}


get_required_value_from_factory_info_yaml() {
  local jq_filter=$1

  ensure_factory_info_specified
  local store_yaml
  store_yaml="$(get_factory_info_store_yaml_filename)"

  local out
  out="$(cat "$store_yaml" | yq -j "$jq_filter")"
  echo "$out"
}


get_value_from_factory_info_yaml() {
  local jq_filter=$1

  local store_yaml
  store_yaml="$(get_factory_info_store_yaml_filename)"
  if ! test -f "$store_yaml"; then
    # 1>&2 echo "WARNING: Factory info store at '$store_yaml' not found when looking for '$jq_filter'."
    echo "null"
    return 0
  fi

  local out
  out="$(cat "$store_yaml" | yq -j "$jq_filter")"
  echo "$out"
}


get_value_from_factory_info_yaml_or_if_null_then_replace_with() {
  null_replacement_value="$2"
  out="$(get_value_from_factory_info_yaml "$1")"
  if [[ "$out" == "null" ]]; then
    out="$null_replacement_value"
  fi
  echo "$out"
}

get_value_from_factory_info_yaml_or_if_null_then_error() {
  out="$(get_required_value_from_factory_info_yaml "$1")"
  if [[ "$out" == "null" ]]; then
    1>&2 echo "ERROR: Unexpected null value found when looking for \`$1\` in factory info config."
    exit 1
  fi
  echo "$out"
}


get_factory_info__user_id() {
  get_value_from_factory_info_yaml_or_if_null_then_replace_with '.user.id' ""
}


get_factory_info__user_full_name() {
  get_value_from_factory_info_yaml_or_if_null_then_replace_with '.user."full-name"' ""
}


get_factory_info__user_email() {
  get_value_from_factory_info_yaml_or_if_null_then_replace_with '.user.email' ""
}


get_factory_info__user_gpg_default_id() {
  get_value_from_factory_info_yaml_or_if_null_then_replace_with '.user.gpg."default-id"' ""
}


get_required_factory_info__user_id() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.user.id'
}


get_required_factory_info__user_full_name() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.user."full-name"'
}


get_required_factory_info__user_email() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.user.email'
}


get_required_factory_info__user_gpg_default_id() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.user.gpg."default-id"'
}


get_required_factory_info__gopass_factory_only_vault_id() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.gopass."factory-only-vault".id'
}


get_required_factory_info__gopass_factory_only_vault_repo_name() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.gopass."factory-only-vault"."repo-name"'
}


get_required_factory_info__gopass_default_device_vault_id() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.gopass."default-device-vault".id'
}


get_required_factory_info__gopass_default_device_vault_repo_name() {
  get_value_from_factory_info_yaml_or_if_null_then_error '.gopass."default-device-vault"."repo-name"'
}


get_required_factory_info__device_defaults_email_domain() {
  get_value_from_factory_info_yaml_or_if_null_then_error '."device-defaults"."email-domain"'
}


prompt_for_factory_info_mandatory__user_id() {
  local value_re="^[a-z0-9_-]+$"
  echo -e "\"user_id\" \u2208 \`${value_re}\`: A factory user id (e.g.: my_user, bob_gauthier)."
  prompt_for_mandatory_parameter_loop "$1" "user_id" "$value_re"
}


prompt_for_factory_info_mandatory__user_full_name() {
  # local value_re="^[a-zA-Z0-9\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s_]+$"
  # TODO: Review this if at some point non latin alphabets are required.
  local value_re="^[a-zA-Z0-9$(get_latin_accented_chars)_ -]+$"
  echo -e "\"user_full_name\" \u2208 \`${value_re}\`: The factory user's full name(e.g.: Étienne Bédard)."
  # TODO: Autocompletion with gpg public id if any.
  prompt_for_mandatory_parameter_loop "$1" "user_full_name" "$value_re"
}


prompt_for_factory_info_mandatory__user_email() {
  local value_re="^[a-zA-Z0-9@\.$(get_latin_accented_chars)_-]+$"
  echo -e "\"user_email\" \u2208 \`${value_re}\`: The factory user's email address (e.g.: ebedard@mydomain.com)."
  # TODO: Autocompletion with gpg public id email if any.
  prompt_for_mandatory_parameter_loop "$1" "user_email" "$value_re"
}


prompt_for_factory_info_mandatory__user_gpg_default_id() {
  local value_re="^[a-zA-Z0-9@\.$(get_latin_accented_chars)_-]+$"
  echo -e "\"user_gpg_default_id\" \u2208 \`${value_re}\`: The factory user's default gpg id. Can be a email address or the gpg public key id (e.g.: ebedard@mydomain.com, AF72B07CD39B7712AC472EB0FA282F683BDE3F7D)."
  # TODO: Autocompletion with available gpg id and current email if any.
  prompt_for_mandatory_parameter_loop "$1" "user_gpg_default_id" "$value_re"
}


prompt_for_factory_info_mandatory__x() {
  local out_var_name="$1"
  local param="$2"
  prompt_for_factory_info_mandatory__${param} "$out_var_name"
}


read_or_prompt_for_factory_info__x() {
  local out_varname="$1"
  local param="$2"
  local param_value="null"
  if is_factory_info_specified; then
    local param_value
  param_value="$(get_factory_info__${param})"
  fi

  if [[ "$param_value" == "null" ]] || [[ "$param_value" == "" ]]; then
    prompt_for_factory_info_mandatory__${param} "$out_varname"
  else
    eval "${out_varname}=\"${param_value}\""
  fi
}


read_or_prompt_for_factory_info__user_id() {
  read_or_prompt_for_factory_info__x "$1" "user_id"
}


read_or_prompt_for_factory_info__user_full_name() {
  read_or_prompt_for_factory_info__x "$1" "user_full_name"
}


read_or_prompt_for_factory_info__user_email() {
  read_or_prompt_for_factory_info__x "$1" "user_email"
}


read_or_prompt_for_factory_info__user_gpg_default_id() {
  read_or_prompt_for_factory_info__x "$1" "user_gpg_default_id"
}


init_factory_state() {
  info_store_path="$(get_factory_info_store_yaml_filename)"

  # TODO: Cli app taking these parameters.

  local _REQ_PARAMS=$(cat <<EOF
user_id
user_full_name
user_email
user_gpg_default_id
EOF
)

  for param in $_REQ_PARAMS; do
    prompt_for_factory_info_mandatory__x "$param" "$param"
  done

  local _JQ_FILTER=$(cat <<EOF
.user.id = \$user_id | \
.user."full-name" = \$user_full_name | \
.user.email = \$user_email | \
.user.gpg."default-id" = \$user_gpg_default_id
EOF
)

  local yaml_str
  yaml_str=$(echo "---" | yq -y \
    --arg user_id "$user_id" \
    --arg user_full_name "$user_full_name" \
    --arg user_email "$user_email" \
    --arg user_gpg_default_id "$user_gpg_default_id" \
    "$_JQ_FILTER")

  printf -- "\n"
  printf -- "Factory info\n"
  printf -- "----------\n\n"

  printf -- "$yaml_str\n\n"

  if ! prompt_for_user_approval; then
    exit 1
  fi

  echo "Writing factory info configuration to '$info_store_path'."
  echo "$yaml_str" > "$info_store_path"
  echo "Current device is now set to '$user_id'."
}
