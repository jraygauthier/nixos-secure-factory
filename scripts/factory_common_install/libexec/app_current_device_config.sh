#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
. "$common_factory_install_libexec_dir/app_current_device_ssh.sh"
. "$common_factory_install_libexec_dir/app_current_device_liveenv.sh"

device_system_update_libexec_dir="$(pkg_nixos_device_system_config_get_libexec_dir)"
. "$device_system_update_libexec_dir/device_system_config.sh"


_rm_existing_factory_ssh_pub_key_from_prod_dev_access() {
  print_title_lvl3 "Removing existing factory user accesses from production devices"

  local device_user="$1"
  local factory_user_id="$2"

  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  local device_ssh_authorized_dir="$device_cfg_repo_root_dir/device_ssh/authorized"
  local rel_ssh_dir_from_root="device_ssh/authorized"
  local rel_json_path_from_root="$rel_ssh_dir_from_root/per_user_authorized_keys.json"
  local json_path="$device_cfg_repo_root_dir/$rel_json_path_from_root"

  local rel_pub_key_path_from_json
  if rel_pub_key_path_from_json="$(
      jq -j \
      --arg factory_user_id "$factory_user_id" \
      --arg device_user "$device_user" \
      '.[$device_user][$factory_user_id].public_key_file' \
      < "$json_path")" && \
      test "" != "$rel_pub_key_path_from_json" &&
      test "null" != "$rel_pub_key_path_from_json"; then
    echo "Factory user already had access to the device. Will update the ssh public key."
    echo_eval "rm -f '$device_ssh_authorized_dir/$rel_pub_key_path_from_json'"
  fi

  local previous_json_content=""
  if test -f "$json_path"; then
    previous_json_content="$(jq '.' < "$json_path")"
  fi
  if test "" = "$previous_json_content"; then
    previous_json_content="{}"
  fi

  json_content="$(
    echo "$previous_json_content" | \
    jq \
    --arg factory_user_id "$factory_user_id" \
    --arg device_user "$device_user" \
    'del(.[$device_user][$factory_user_id])')"

  echo "Removing '$factory_user_id' factory user from '$rel_json_path_from_root'."
  echo "echo '\$json_content' > '$json_path'"
  echo "$json_content" > "$json_path"

  print_title_lvl4 "Content of '$rel_json_path_from_root'"
  echo "$json_content"
}


deny_factory_ssh_access_to_production_device() {
  print_title_lvl2 "Denying factory user access to production devices via ssh"

  # All users by default.
  local device_user="${1:-}"
  local factory_user_id="${2:-}"

  if test "" == "$factory_user_id"; then
    factory_user_id="$(get_required_factory_info__user_id)"
  fi

  _rm_existing_factory_ssh_pub_key_from_prod_dev_access "$device_user" "$factory_user_id"
}


# shellcheck disable=2120 # Optional arguments.
grant_factory_ssh_access_to_production_device() {
  print_title_lvl2 "Granting factory user access to production devices via ssh"

  # All users by default.
  local device_user="${1:-}"
  local factory_user_id="${2:-}"

  if test "" == "$factory_user_id"; then
    factory_user_id="$(get_required_factory_info__user_id)"
  fi

  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  _rm_existing_factory_ssh_pub_key_from_prod_dev_access "$factory_user_id" "$device_user"

  local device_ssh_authorized_dir="$device_cfg_repo_root_dir/device_ssh/authorized"
  local rel_ssh_dir_from_root="device_ssh/authorized"
  local rel_json_path_from_root="$rel_ssh_dir_from_root/per_user_authorized_keys.json"
  local json_path="$device_cfg_repo_root_dir/$rel_json_path_from_root"

  local rel_pub_key_path_from_json
  if rel_pub_key_path_from_json="$(
      jq -j \
      --arg factory_user_id "$factory_user_id" \
      --arg device_user "$device_user" \
      '.[$device_user][$factory_user_id].public_key_file' \
      < "$json_path")" && test "" != "$rel_pub_key_path_from_json"; then
    echo "Factory user already had access to the device. Will update the ssh public key."
    echo_eval "rm -f '$device_ssh_authorized_dir/$rel_pub_key_path_from_json'"
  fi

  local factory_pub_key_filename
  factory_pub_key_filename="$(get_current_user_ssh_public_key_path)"

  local factory_pub_key_basename
  factory_pub_key_basename="$(basename "$factory_pub_key_filename")"

  local rel_pub_key_path_from_json="./public_keys/${factory_user_id}_${factory_pub_key_basename}"
  local rel_pub_key_path_from_root="$rel_ssh_dir_from_root/$rel_pub_key_path_from_json"
  local pub_key_path="$device_cfg_repo_root_dir/$rel_pub_key_path_from_root"

  local previous_json_content=""
  if test -f "$json_path"; then
    previous_json_content="$(jq '.' < "$json_path")"
  fi
  if test "" = "$previous_json_content"; then
    previous_json_content="{}"
  fi

  local json_content
  json_content="$(
    echo "$previous_json_content" | jq \
    --arg factory_user_id "$factory_user_id" \
    --arg device_user "$device_user" \
    --arg rel_pub_key_path_from_json "$rel_pub_key_path_from_json" \
    '.[$device_user][$factory_user_id].public_key_file = $rel_pub_key_path_from_json')"

  rel_pub_key_path_from_root="$rel_ssh_dir_from_root/$rel_pub_key_path_from_json"

  echo "Copying '$factory_pub_key_filename'  to '$pub_key_path'."
  echo_eval "cp -p '$factory_pub_key_filename' '$pub_key_path'"

  # Update the file with the new content.
  echo "Updating '$rel_json_path_from_root' with new keys at '$rel_pub_key_path_from_root'."
  echo "echo '\$json_content' > '$json_path'"
  echo "$json_content" > "$json_path"

  print_title_lvl3 "Content of '$rel_json_path_from_root'"
  echo "$json_content"
}


build_current_device_config() {
  print_title_lvl2 "Building current device configuration"

  local out_var_name="$1"
  local config_name="${2:-release}"

  local device_id
  device_id="$(get_required_current_device_id)" || return 1

  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  local config_filename="$device_cfg_repo_root_dir/${config_name}.nix"

  build_device_config_dir "$out_var_name" "$config_filename" "$device_id"
  echo "${out_var_name}='$(eval "echo \$${out_var_name}")'"
}


# shellcheck disable=2120 # Optional arguments.
build_current_device_config_system_closure() {
  print_title_lvl2 "Building current device configuration system closure"
  local out_var_name="$1"
  local config_name="${2:-release}"
  local cfg_closure="${3:-}"

  if [[ -z "$cfg_closure" ]]; then
    build_current_device_config "cfg_closure" "$config_name"
  fi

  build_device_config_system_closure "$out_var_name" "$cfg_closure"
}


sent_config_closure_to_device() {
  print_title_lvl2 "Sending configuration closure to device"
  local cfg_closure="$1"
  # copy_nix_closure_to_device "$cfg_closure"
  # nix copy --to file:///mnt "$cfg_closure"

  local device_hostname
  local device_ssh_port
  read_or_prompt_for_current_device__hostname "device_hostname"
  read_or_prompt_for_current_device__ssh_port "device_ssh_port"

  local ssh_port_args
  ssh_port_args="$(build_ssh_port_args_for_ssh_port "$device_ssh_port")"
  NIX_SSHOPTS="${ssh_port_args}" \
    nix copy --to "ssh://root@${device_hostname}" "$cfg_closure"
}


sent_initial_config_closure_to_device() {
  sent_config_closure_to_device "$1"
}


# _REMOTE_LIVEENV_NIX_STORE_ROOT="/mnt/other"
_REMOTE_LIVEENV_NIX_STORE_ROOT="/mnt"


_send_system_closure_to_device_impl() {
  local system_closure="$1"
  local remote="$2"
  # copy_nix_closure_to_device "$cfg_closure"
  # nix copy --to file:///mnt "$cfg_closure"

  local device_hostname
  local device_ssh_port
  read_or_prompt_for_current_device__hostname "device_hostname"
  read_or_prompt_for_current_device__ssh_port "device_ssh_port"

  local ssh_port_args
  ssh_port_args="$(build_ssh_port_args_for_ssh_port "$device_ssh_port")"
  NIX_SSHOPTS="${ssh_port_args}" \
    nix copy --to "$remote" "$system_closure"
}


send_initial_system_closure_to_device() {
  print_title_lvl2 "Sending initial system closure to device"
  local remote="ssh://root@${device_hostname}?remote-store=local?root=${_REMOTE_LIVEENV_NIX_STORE_ROOT}"
  _send_system_closure_to_device_impl "$1" "$remote"
}


send_system_closure_to_device() {
  print_title_lvl2 "Sending system closure to device"
  local remote="ssh://root@${device_hostname}"
  _send_system_closure_to_device_impl "$1" "$remote"
}


install_initial_system_closure_to_device() {
  print_title_lvl2 "Installing initial system closure on device"
  local system_closure="$1"

  local cmd
  cmd=$(cat <<EOF
nixos-install \
  --substituters "$_REMOTE_LIVEENV_NIX_STORE_ROOT" \
  --no-root-passwd --no-channel-copy \
  --system "$system_closure"
EOF
)
  run_cmd_as_device_root "$cmd"
}


install_system_closure_to_device() {
  print_title_lvl2 "Installing system closure on device"
  local system_closure="$1"

  local profile=/nix/var/nix/profiles/system
  local profile_name="system"
  # local action="test"
  # local action="dry-activate"
  local action="switch"


  if [ "$profile_name" != system ]; then
    profile="/nix/var/nix/profiles/system-profiles/$system_closure"
    mkdir -p -m 0755 "$(dirname "$profile")"
  fi

  local cmd
  cmd=$(cat <<EOF
nix-env -p "$profile" --set "$system_closure"
EOF
)
  run_cmd_as_device_root "$cmd"

  local cmd2
  cmd2=$(cat <<EOF
$system_closure/bin/switch-to-configuration "$action" || \
  { echo "warning: error(s) occurred while switching to the new configuration" >&2; exit 1; }
EOF
)

  run_cmd_as_device_root "$cmd2"
}


_build_and_deploy_initial_device_config_impl() {
  local config_name="${1:-release}"

  # Make sure current factory user has access to device via ssh.
  grant_factory_ssh_access_to_production_device ""
  local system_closure
  build_current_device_config_system_closure "system_closure" "$config_name" ""
  mount_liveenv_nixos_partitions
  send_initial_system_closure_to_device "$system_closure"
  install_initial_system_closure_to_device "$system_closure"
}


_build_and_deploy_device_config_impl() {
  local config_name="${1:-release}"
  local system_closure
  build_current_device_config_system_closure "system_closure" "$config_name" ""
  send_system_closure_to_device "$system_closure"
  install_system_closure_to_device "$system_closure"
}


build_and_deploy_device_config() {
  local config_name="${1:-release}"
  if is_device_run_from_nixos_liveenv; then
    print_title_lvl1 "Building, deploying and installing initial device configuration"
    _build_and_deploy_initial_device_config_impl "$config_name"
  else
    print_title_lvl1 "Building, deploying and installing device configuration"
    _build_and_deploy_device_config_impl "$config_name"
  fi
}


update_device_config() {
  # TODO: Implement.
  local cmd
  cmd=$(cat <<EOF
false
EOF
)
  run_cmd_as_device_root "$cmd"
}


update_device_os() {
  update_device_config
  # TODO: Update secrets too.
}
