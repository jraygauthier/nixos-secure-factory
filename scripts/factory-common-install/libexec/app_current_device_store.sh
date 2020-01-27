#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
# Source both dependencies.
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/prompt.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"
. "$common_factory_install_libexec_dir/workspace_paths.sh"



get_current_device_store_yaml_filename() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_nixos_secure_factory_workspace_dir)"
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
    { 1>&2 echo "ERROR: '$store_yaml_basename' file does not exists in '$store_yaml_dirname'."; return 1; }
}


print_current_device_state() {
  local filename
  filename="$(get_current_device_store_yaml_filename)"
  print_title_lvl1 "Content of '$filename':"

  ensure_factory_info_specified || return 1
  cat "$filename"
}


rm_current_device_state() {
  local filename
  filename="$(get_current_device_store_yaml_filename)" || return 1
  print_title_lvl1 "Removing '$filename':"

  if ! [[ -e "$filename" ]]; then
    echo "Nothing do remove."
    return 0
  fi

  print_title_lvl2 "Content is:"
  cat "$filename"

  if ! prompt_for_user_approval; then
    return 1
  fi

  echo_eval "rm '$filename'"
}


get_value_from_current_device_yaml() {
  local jq_filter=$1

  ensure_current_device_specified || return 1
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
  out="$(get_value_from_current_device_yaml "$1")" || return 1
  if [[ "$out" == "null" ]]; then
    1>&2 echo "ERROR: Unexpected null value found when looking for \`$1\` in current device config."
    return 1
  fi
  echo "$out"
}


get_required_current_device_id() {
  get_value_from_current_device_yaml_or_if_null_then_error '.identifier' || return 1
}


get_required_current_device_dirname() {
  get_required_current_device_id || return 1
}


get_required_current_device_type() {
  get_value_from_current_device_yaml_or_if_null_then_error '.type'
}


get_current_device_hostname() {
  get_value_from_current_device_yaml_or_if_null_then_replace_with '.hostname' ""
}


get_resolved_current_device_hostname() {
  local out
  out="$(get_current_device_hostname)" || return 1

  # TODO: auto -> retrieve from backend (e.g.: vbox backend).
  if [[ "$out" == "auto" ]]; then
    out="localhost"
  fi

  echo "$out"
}


get_required_current_device_hostname() {
  local out
  out="$(get_resolved_current_device_hostname)" || return 1

  if [[ "$out" == "null" ]] || [[ "$out" == "" ]]; then
    1>&2 echo "ERROR: ${FUNCNAME[0]}: Empty or null device hostname."
    return 1
  fi

  echo "$out"
}


get_current_device_ssh_port() {
  get_value_from_current_device_yaml_or_if_null_then_replace_with '."ssh-port"' ""
}


get_resolved_current_device_ssh_port() {
  local out
  out="$(get_current_device_ssh_port)" || return 1

  # TODO: auto -> retrieve from backend (e.g.: vbox backend).
  if [[ "$out" == "auto" ]]; then
    out="2222"
  fi

  echo "$out"
}


get_required_current_device_ssh_port() {
  local out
  out="$(get_resolved_current_device_ssh_port)" || return 1

  if [[ "$out" == "null" ]] || [[ "$out" == "" ]]; then
    1>&2 echo "ERROR: ${FUNCNAME[0]}: Empty or null device ssh port."
    return 1
  fi

  echo "$out"
}


_build_device_email_from_device_id() {
  local device_id="$1"

  local email_domain
  email_domain="$(get_required_factory_info__device_defaults_email_domain)"
  echo "${device_id}@${email_domain}"
}


get_required_current_device_email() {
  local device_id
  device_id="$(get_required_current_device_id)" || return 1

  local default_email
  default_email="$(_build_device_email_from_device_id "$device_id")"

  local email
  email="$(get_value_from_current_device_yaml_or_if_null_then_replace_with '."email"' "$default_email")"
  echo "$email"
}


has_current_device_gpg_id() {
  local gpg_id
  gpg_id="$(get_value_from_current_device_yaml '."gpg-id"')" || return 1

  ! [[ "$gpg_id" == "null" ]]
}


get_current_device_gpg_id() {
  local gpg_id
  gpg_id="$(get_value_from_current_device_yaml_or_if_null_then_error '."gpg-id"')"
  echo "$gpg_id"
}


get_current_device_gpg_id_or_email() {
  local default_gpg_id
  default_gpg_id="$(get_required_current_device_email)"

  local gpg_id
  gpg_id="$(get_value_from_current_device_yaml_or_if_null_then_replace_with '."gpg-id"' "$default_gpg_id")"
  echo "$gpg_id"
}


store_current_device_gpg_id() {
  local gpg_id="$1"
  ensure_current_device_specified
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"

  local yaml_str
  yaml_str="$(\
    yq -y --arg gpg_id "$gpg_id" '."gpg-id" = $gpg_id' \
      < "$(get_current_device_store_yaml_filename)")"

  # echo "yaml_str='$yaml_str'"

  echo "Writing device configuration to '$store_yaml'."
  echo "$yaml_str" > "$store_yaml"

  update_device_json_from_current_yaml
}


get_required_current_device_root_dir() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)" || return 1
  local device_dirname
  device_dirname="$(get_required_current_device_dirname)" || return 1
  local out_root_dir="$device_cfg_repo_root_dir/device/$device_dirname"
  test -d "$out_root_dir" || \
    { 1>&2 echo "ERROR: current device root dir at \`$out_root_dir\` does not exists."; return 1; }
  echo "$out_root_dir"
}


get_required_current_device_type_config_root_dir() {
  local device_cfg_type_defs_dir
  device_cfg_type_defs_dir="$(get_device_cfg_type_definitions_root_dir)" || return 1
  local type
  type="$(get_required_current_device_type)" || return 1
  out_root_dir="$device_cfg_type_defs_dir/$type"
  test -d "$out_root_dir" || \
    { 1>&2 echo "ERROR: current device type config root dir at \`$out_root_dir\` does not exists."; return 1; }
  echo "$out_root_dir"
}


get_required_current_device_type_factory_install_root_dir() {
  local device_type_defs_dir
  device_type_defs_dir="$(get_factory_install_device_type_definitions_root_dir)"
  local type
  type="$(get_required_current_device_type)" || return 1
  out_root_dir="$device_type_defs_dir/$type"
  test -d "$out_root_dir" || \
    { 1>&2 echo "ERROR: current device type factory install root dir at \`$out_root_dir\` does not exists."; return 1; }
  echo "$out_root_dir"
}


update_device_json_from_current_yaml() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_writable_device_cfg_repo_root_dir)"

  ensure_current_device_specified

  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"
  local store_yaml_basename="$(basename "$store_yaml")"
  local store_yaml_dirname="$(dirname "$store_yaml")"

  local device_dirname
  device_dirname="$(get_required_current_device_dirname)"
  local json_str
  json_str="$(cat "$store_yaml" | yq '.')"

  local dev_cfg_dir="$device_cfg_repo_root_dir/device/$device_dirname"
  echo "Creating device config directory: \`$dev_cfg_dir\`"
  mkdir -p "$dev_cfg_dir"
  echo "Updating \`$dev_cfg_dir/device.json\` from \`$store_yaml\`."
  echo "$json_str" | yq '.' > "$dev_cfg_dir/device.json"
}


list_available_device_types() {
  local device_cfg_type_defs_dir
  device_cfg_type_defs_dir="$(get_device_cfg_type_definitions_root_dir)" || return 1

  find "$device_cfg_type_defs_dir" -mindepth 1 -maxdepth 1 | xargs -r -l1 basename
}


prompt_for_device_mandatory__device_type() {
  local avail_types
  avail_types="$(list_available_device_types)" || return 1
  echo -e "\"type\" \u2208 {$(echo "$avail_types" | sed -E -e "s/^(.+)$/\'\1\'/g" | paste -d',' -s | sed 's/,/, /g')}"
  # TODO: This is weak. We're lucky that our elements do not have spaces.
  prompt_for_custom_choices_strict_loop "$1" "type: " $(echo "$avail_types" | paste -s -d' ')
}


prompt_for_device_mandatory__device_id() {
  local value_re="^[a-z0-9-]+$"
  echo -e "\"device_id\" \u2208 \`${value_re}\`: A unique human readable id for this particular device (e.g.: 'my-office-device', 'my-personal-device-55')."
  prompt_for_mandatory_parameter_loop "$1" "device_id" "$value_re"
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
  echo -e "\"ssh_port\": the ssh port to reach the device through specified \"hostname\" (e.g.: '22', '2222'). Default is 'auto'"
  local value_re="^[0-9]*$"
  prompt_for_optional_parameter_loop "$1" "ssh_port" "$value_re"
}


prompt_for_device_optional__uart_pty() {
  local value_re="^[a-zA-Z0-9\.-\/]*$"
  echo -e "\"uart_pty\": the path to the uart pty connected to the device (e.g.: '/dev/ttyS0'). Default is 'auto'"
  prompt_for_optional_parameter_loop "$1" "uart_pty" "$value_re"
}


prompt_for_device_optional__x() {
  local out_var_name="$1"
  local param="$2"
  prompt_for_device_optional__${param} "$out_var_name"
}


validate_device_id() {
  local device_id="$1"
  local value_re="^[a-z0-9-]+$"
  if ! echo "$device_id" | grep -Eq "$value_re"; then
    1>&2 echo "ERROR: Device id value of '$device_id' is not allowed to contain characters not in the set: \`$value_re\`."
    return 1
  fi
}


init_new_current_device_state_cli() {
  local store_yaml
  store_yaml="$(get_current_device_store_yaml_filename)"

  # TODO: Cli app that takes these parameters.

  local device_id
  local device_type
  local hostname
  local ssh_port
  local uart_pty
  local backend

  local _REQ_PARAMS=$(cat <<EOF
device_id
device_type
EOF
)

  for param in $_REQ_PARAMS; do
    prompt_for_device_mandatory__x "$param" "$param"
  done

  local _NON_VM_REQ_PARAMS=$(cat <<EOF
hostname
EOF
)

  local _NON_VM_OPT_PARAMS=$(cat <<EOF
ssh_port
uart_pty
EOF
)

  if test "$device_type" == "virtual-box-vm"; then
    # This should already be well defined for a VM using
    # "NAT" network adapter config.
    backend="virtual_box"
    hostname="auto"
    ssh_port="auto"
    uart_pty="auto"
  else
    backend="bare_metal"
    for param in $_NON_VM_REQ_PARAMS; do
      prompt_for_device_mandatory__x "$param" "$param"
    done

    for param in $_NON_VM_OPT_PARAMS; do
      prompt_for_device_optional__x "$param" "$param"
    done

    if [[ -z "$ssh_port" ]]; then
      ssh_port="auto"
    fi
    if [[ -z "$uart_pty" ]]; then
      uart_pty="auto"
    fi
  fi

  local email
  email="$(_build_device_email_from_device_id "$device_id")"

  # Will be the device's email until the device's secrets are
  # first created, at which time a real gpg id should be set.
  local gpg_id="$email"


  local _JQ_FILTER
  _JQ_FILTER="$(cat <<EOF
.identifier = \$device_id | \
.type = \$device_type | \
.backend = \$backend | \
.hostname = \$hostname | \
."ssh-port" = \$ssh_port | \
."uart-pty" = \$uart_pty | \
."email" = \$email | \
."gpg-id" = \$gpg_id
EOF
)"

  local yaml_str
  yaml_str=$(echo "---" | yq -y \
    --arg device_id "$device_id" \
    --arg device_type "$device_type" \
    --arg backend "$backend" \
    --arg hostname "$hostname" \
    --arg ssh_port "$ssh_port" \
    --arg uart_pty "$uart_pty" \
    --arg email "$email" \
    --arg gpg_id "$gpg_id" \
    "$_JQ_FILTER")

  printf -- "Device info\n"
  printf -- "-----------\n\n"

  printf -- "%s\n\n" "$yaml_str"

  if ! prompt_for_user_approval; then
    return 1
  fi

  echo "Writing device configuration to '$store_yaml'."
  echo "$yaml_str" > "$store_yaml"
  echo "Current device is now set to \`$device_id\`."

  update_device_json_from_current_yaml

  # TODO: Consider moving this at a higher level and
  # also mouting the device store via 'mount_gopass_factory_cdevice_substores'.
}
