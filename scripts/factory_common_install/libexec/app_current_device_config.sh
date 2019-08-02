#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
. "$common_factory_install_libexec_dir/app_current_device_ssh.sh"
. "$common_factory_install_libexec_dir/app_current_device_liveenv.sh"

_rm_existing_factory_ssh_pub_key_from_prod_dev_access() {
  print_title_lvl3 "Removing existing factory user accesses from production devices"

  local factory_user_id="$1"

  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  local device_access_ssh_dir="$device_cfg_repo_root_dir/device_access/ssh"
  local rel_ssh_dir_from_root="device_access/ssh"
  local rel_json_path_from_root="$rel_ssh_dir_from_root/per_user_authorized_keys.json"
  local json_path="$device_cfg_repo_root_dir/$rel_json_path_from_root"

  local rel_pub_key_path_from_json
  if rel_pub_key_path_from_json="$(
      jq -j \
      --arg factory_user_id "$factory_user_id" \
      '.root[$factory_user_id].public_key_file' \
      < "$json_path")" && \
      test "" != "$rel_pub_key_path_from_json" &&
      test "null" != "$rel_pub_key_path_from_json"; then
    echo "Factory user already had access to the device. Will update the ssh public key."
    echo_eval "rm -f '$device_access_ssh_dir/$rel_pub_key_path_from_json'"
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
    'del(.root[$factory_user_id])')"

  echo "Removing '$factory_user_id' factory user from '$rel_json_path_from_root'."
  echo "echo '\$json_content' > '$json_path'"
  echo "$json_content" > "$json_path"

  print_title_lvl4 "Content of '$rel_json_path_from_root'"
  echo "$json_content"
}


deny_factory_ssh_access_to_production_device() {
  print_title_lvl2 "Denying factory user access to production devices via ssh"

  local factory_user_id="${1:-}"
  if test "" == "$factory_user_id"; then
    factory_user_id="$(get_required_factory_info__user_id)"
  fi

  _rm_existing_factory_ssh_pub_key_from_prod_dev_access "$factory_user_id"
}


# shellcheck disable=2120 # Optional arguments.
grant_factory_ssh_access_to_production_device() {
  print_title_lvl2 "Granting factory user access to production devices via ssh"

  local factory_user_id="${1:-}"
  if test "" == "$factory_user_id"; then
    factory_user_id="$(get_required_factory_info__user_id)"
  fi

  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  _rm_existing_factory_ssh_pub_key_from_prod_dev_access "$factory_user_id"

  local device_access_ssh_dir="$device_cfg_repo_root_dir/device_access/ssh"
  local rel_ssh_dir_from_root="device_access/ssh"
  local rel_json_path_from_root="$rel_ssh_dir_from_root/per_user_authorized_keys.json"
  local json_path="$device_cfg_repo_root_dir/$rel_json_path_from_root"

  local rel_pub_key_path_from_json
  if rel_pub_key_path_from_json="$(
      jq -j \
      --arg factory_user_id "$factory_user_id" \
      '.root[$factory_user_id].public_key_file' \
      < "$json_path")" && test "" != "$rel_pub_key_path_from_json"; then
    echo "Factory user already had access to the device. Will update the ssh public key."
    echo_eval "rm -f '$device_access_ssh_dir/$rel_pub_key_path_from_json'"
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
    --arg rel_pub_key_path_from_json "$rel_pub_key_path_from_json" \
    '.root[$factory_user_id].public_key_file = $rel_pub_key_path_from_json')"

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


build_device_config() {
  print_title_lvl2 "Building device configuration"

  local out_var_name="$1"

  local device_id
  device_id="$(get_required_current_device_id)" || return 1

  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_device_cfg_repo_root_dir)"

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/system"

  nix build --out-link "$outLink" \
    -f "$device_cfg_repo_root_dir/release.nix" \
    --argstr device_identifier "$device_id" \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }

  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
}


# shellcheck disable=2120 # Optional arguments.
build_device_config_system_closure() {
  print_title_lvl2 "Building device configuration system closure"
  local out_var_name="$1"
  local cfg_closure="${2:-}"

  if [[ -z "$cfg_closure" ]]; then
    build_device_config "cfg_closure"
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/system"

  nix build \
    --out-link "$outLink" \
    -I "nixpkgs=${cfg_closure}/pinned_nixpkgs" \
    -I "nixos-config=${cfg_closure}/configuration.nix" \
    -f "${cfg_closure}/pinned_nixos" system \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
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


# _REMOTE_NIX_STORE_ROOT="/mnt/other"
_REMOTE_NIX_STORE_ROOT="/mnt"


sent_system_closure_to_device() {
  print_title_lvl2 "Sending system closure to device"
  local system_closure="$1"
  # copy_nix_closure_to_device "$cfg_closure"
  # nix copy --to file:///mnt "$cfg_closure"

  local device_hostname
  local device_ssh_port
  read_or_prompt_for_current_device__hostname "device_hostname"
  read_or_prompt_for_current_device__ssh_port "device_ssh_port"

  local ssh_port_args
  ssh_port_args="$(build_ssh_port_args_for_ssh_port "$device_ssh_port")"
  NIX_SSHOPTS="${ssh_port_args}" \
    nix copy --to "ssh://root@${device_hostname}?remote-store=local?root=${_REMOTE_NIX_STORE_ROOT}" "$system_closure"
}

install_config_to_device() {
  print_title_lvl2 "Installing device configuration on device"
  local cfg_closure="$1"

  local cmd
  cmd=$(cat <<EOF
    NIXOS_CONFIG="$cfg_closure/configuration.nix" \
      nixos-install \
        --no-root-passwd --no-channel-copy \
        -I "nixpkgs=${cfg_closure}/pinned_nixpkgs" \
        -I "nixos=${cfg_closure}/pinned_nixos" \
        -I "nixos-config=${cfg_closure}/configuration.nix"
EOF
)
  run_cmd_as_device_root "$cmd"
}


install_system_closure_to_device() {
  print_title_lvl2 "Installing system closure on device"
  local system_closure="$1"

  local cmd
  cmd=$(cat <<EOF
    nixos-install \
      --substituters "$_REMOTE_NIX_STORE_ROOT" \
      --no-root-passwd --no-channel-copy \
      --system "$system_closure"
EOF
)
  run_cmd_as_device_root "$cmd"
}


build_and_deploy_device_config() {
  print_title_lvl1 "Building, deploying and installing device configuration"

  # Make sure current factory user has access to device via ssh.
  grant_factory_ssh_access_to_production_device ""
  local system_closure
  build_device_config_system_closure "system_closure" ""
  mount_liveenv_nixos_partitions
  sent_system_closure_to_device "$system_closure"
  install_system_closure_to_device "$system_closure"
}


build_and_deploy_device_config_alt() {
  print_title_lvl1 "Building, deploying and installing device configuration (alternative method)"

  # Make sure current factory user has access to device via ssh.
  grant_factory_ssh_access_to_production_device ""
  local cfg_closure
  build_device_config "cfg_closure"
  mount_liveenv_nixos_partitions
  sent_config_closure_to_device "$cfg_closure"
  install_config_to_device "$cfg_closure"
}
