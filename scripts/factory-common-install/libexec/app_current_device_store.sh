#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
# Source both dependencies.
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/prompt.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"



get_current_device_store_yaml_filename() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"
  echo "$device_cfg_repo_root_dir/.current-device.yaml"
}


is_current_device_specified() {
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"
  test -f "$store_yaml"
}

ensure_current_device_specified() {
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"
  local store_yaml_basename="$(basename "$store_yaml")"
  local store_yaml_dirname="$(dirname "$store_yaml")"
  is_current_device_specified || \
    { 1>&2 echo "ERROR: '$store_yaml_basename' file does not exists in '$store_yaml_dirname'."; exit 1; }
}


get_value_from_current_device_yaml() {
  local jq_filter=$1

  ensure_current_device_specified || exit 1
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"

  local out
  out="$(cat "$store_yaml" | yq -j "$jq_filter")"
  echo "$out"
}


get_value_from_current_device_yaml_or_if_null_then_replace_with() {
  null_replacement_value="$2"
  local out
  if ! out="$(get_value_from_current_device_yaml "$1")"; then
    out="$null_replacement_value"
  fi
  if [[ "$out" == "null" ]]; then
    out="$null_replacement_value"
  fi
  echo "$out"
}


get_value_from_current_device_yaml_or_if_null_then_error() {
  local out
  out="$(get_value_from_current_device_yaml "$1")" || exit 1
  if [[ "$out" == "null" ]]; then
    1>&2 echo "ERROR: Unexpected null value found when looking for \`$1\` in current device config."
    exit 1
  fi
  echo "$out"
}


get_required_current_device_dirname() {
  get_value_from_current_device_yaml_or_if_null_then_error '.dirname' || exit 1
}


get_required_current_device_type() {
  get_value_from_current_device_yaml_or_if_null_then_error '.type'
}


get_current_device_hostname() {
  get_value_from_current_device_yaml_or_if_null_then_replace_with '.hostname' ""
}


get_current_device_ssh_port() {
  get_value_from_current_device_yaml_or_if_null_then_replace_with '.ssh_port' ""
}


get_required_current_device_id() {
  get_required_current_device_dirname || exit 1
}


get_required_current_device_email() {
  local email_domain
  email_domain="$(get_required_factory_info__device_defaults_email_domain)"
  local device_id
  device_id="$(get_required_current_device_id)" || exit 1
  echo "${device_id}@${email_domain}"
}


get_required_current_device_root_dir() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"
  local dirname
  dirname="$(get_required_current_device_dirname)"
  local out_root_dir="$device_cfg_repo_root_dir/device/$dirname"
  test -d "$out_root_dir" || \
    { 2>&1 echo "ERROR: current device root dir at \`$out_root_dir\` does not exists."; exit 1; }
  echo "$out_root_dir"
}


get_required_current_device_type_config_root_dir() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"
  local type
  type="$(get_required_current_device_type)"
  out_root_dir="$device_cfg_repo_root_dir/device-type/$type"
  test -d "$out_root_dir" || \
    { 2>&1 echo "ERROR: current device type config root dir at \`$out_root_dir\` does not exists."; exit 1; }
  echo "$out_root_dir"
}


get_required_current_device_type_factory_install_root_dir() {
  local factory_install_repo_root_dir
  factory_install_repo_root_dir="$(get_factory_install_repo_root_dir)"
  local type
  type="$(get_required_current_device_type)"
  out_root_dir="$factory_install_repo_root_dir/device-type/$type"
  test -d "$out_root_dir" || \
    { 2>&1 echo "ERROR: current device type factory install root dir at \`$out_root_dir\` does not exists."; exit 1; }
  echo "$out_root_dir"
}


update_device_json_from_current_yaml() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  ensure_current_device_specified

  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"
  local store_yaml_basename="$(basename "$store_yaml")"
  local store_yaml_dirname="$(dirname "$store_yaml")"

  local dirname
  dirname="$(get_required_current_device_dirname)"
  local json_str
  json_str="$(cat "$store_yaml" | yq '.')"

  local dev_cfg_dir="$device_cfg_repo_root_dir/device/$dirname"
  echo "Creating device config directory: \`$dev_cfg_dir\`"
  mkdir -p "$dev_cfg_dir"
  echo "Updating \`$dev_cfg_dir/device.json\` from \`$store_yaml\`."
  echo "$json_str" | yq '.' > "$dev_cfg_dir/device.json"
}


list_available_device_types() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  find "$device_cfg_repo_root_dir/device-type" -mindepth 1 -maxdepth 1 | xargs -r -l1 basename
}


prompt_for_device_mandatory__type() {
  local avail_types
  avail_types="$(list_available_device_types)" || return 1
  echo -e "\"type\" \u2208 {$(echo "$avail_types" | sed -E -e "s/^(.+)$/\'\1\'/g" | paste -d',' -s | sed 's/,/, /g')}"
  # TODO: This is weak. We're lucky that our elements do not have spaces.
  prompt_for_custom_choices_strict_loop "$1" "type: " $(echo "$avail_types" | paste -s -d' ')
}


prompt_for_device_mandatory__city() {
  local value_re="^[a-z0-9-]+$"
  echo -e "\"city\" \u2208 \`${value_re}\`: The city the device will be shipped to (e.g.: 'quebec', 'lost-angeles')."
  prompt_for_mandatory_parameter_loop "$1" "city" "$value_re"
}


prompt_for_device_mandatory__organization() {
  local value_re="^[a-z0-9-]+$"
  echo -e "\"organization\" \u2208 \`${value_re}\`: The organization which will own the device (e.g.: 'british-airways')."
  prompt_for_mandatory_parameter_loop "$1" "organization" "$value_re"
}


prompt_for_device_mandatory__short_misc_desc() {
  local value_re="^[a-z0-9-]+$"
  echo -e "\"short_misc_desc\" \u2208 \`${value_re}\`: A short human readable id for this particular device (e.g.: 'office-100', 'britany-mcmarry')."
  prompt_for_mandatory_parameter_loop "$1" "short_misc_desc" "$value_re"
}


prompt_for_device_mandatory__hostname() {
  echo -e "\"hostname\": the hostname or ip address to reach the device (e.g.: 'localhost', 'my-machine', '192.168.0.102')"
  local value_re="^[a-zA-Z0-9.-]+$"
  prompt_for_mandatory_parameter_loop "$1" "hostname" "$value_re"
}


prompt_for_device_mandatory__x() {
  local out_var_name="$1"
  local param="$2"
  prompt_for_device_mandatory__${param} "$out_var_name"
}


prompt_for_device_optional__ssh_port() {
  echo -e "\"ssh_port\": the ssh port to reach the device through specified \"hostname\" (e.g.: '22', '2222'). Default is '22'"
  local value_re="^[0-9]+$"
  prompt_for_optional_parameter_loop "$1" "ssh_port" "$value_re"
}


prompt_for_device_optional__uart_pty() {
  local value_re="^[a-zA-Z0-9.-/]+$"
  echo -e "\"uart_pty\": the path to the uart pty connected to the device (e.g.: '/dev/ttyS0'). Default is 'none'"
  prompt_for_optional_parameter_loop "$1" "uart_pty" "$value_re"
}


prompt_for_device_optional__x() {
  local out_var_name="$1"
  local param="$2"
  prompt_for_device_optional__${param} "$out_var_name"
}


print_current_device_state() {
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"
  print_title_lvl1 "Current device state"
  cat "$store_yaml"
}


init_new_current_device_state() {
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"

  # TODO: Cli app that takes these parameters.

  dirname="${city}_${organization}_${short_misc_desc}_${short_uuid}"


  _JQ_FILTER=$(cat <<EOF
.dirname = \$dirname | \
.type = \$type | \
.backend = \$backend | \
.hostname = \$hostname | \
.ssh_port = \$ssh_port | \
.uart_pty = \$uart_pty
EOF
)

  yaml_str=$(echo "---" | yq -y \
    --arg dirname "$dirname" \
    --arg "type" "$type" \
    --arg backend "$backend" \
    --arg hostname "$hostname" \
    --arg ssh_port "$ssh_port" \
    --arg uart_pty "$uart_pty" \
    "$_JQ_FILTER")

  printf -- "Device info\n"
  printf -- "-----------\n\n"

  printf -- "$yaml_str\n\n"

  if ! prompt_for_user_approval; then
    exit 1
  fi

  echo "Writing device configuration to '$store_yaml'."
  echo "$yaml_str" > "$store_yaml"
  echo "Current device is now set to \`$dirname\`."

  update_device_json_from_current_yaml

  # TODO: Consider moving this at a higher level and
  # also mouting the device store via 'mount_gopass_device'.
}
