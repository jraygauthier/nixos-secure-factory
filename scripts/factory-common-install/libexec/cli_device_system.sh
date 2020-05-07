#!/usr/bin/env bash

device_system_config_updater_libexec_dir="$(pkg-nixos-sf-device-system-config-updater-get-libexec-dir)"
. "$device_system_config_updater_libexec_dir/local_system_updater.sh"

common_factory_install_libexec_dir="$(pkg-nixos-sf-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/app_current_device_config.sh"



_build_ssh_cmd_args() {
  local -n _out_cmd_args="$1"
  shift 1
  if [[ "0" -eq "$#" ]]; then
    _out_cmd_args=""
  else
    printf -v _out_cmd_args '%q ' "$@"
  fi
}


_update_device_config() {
  # TODO: Implement.
  local cmd
  cmd=$(cat <<EOF
false
EOF
)
  run_cmd_as_device_root "$cmd"
}


_run_device_cmd_as_user_w_tty_w_args() {
  local user="${1?}"
  shift 1

  local cmd_args_str
  _build_ssh_cmd_args cmd_args_str "$@"
  # echo "cmd_args_str='$cmd_args_str'"
  # -t: Allocate tty so that we can send proper Ctrl+C and await for
  # it to be processed.
  run_cmd_as_user "$user" \
    "${cmd_args_str}" \
    -t
}


update_device_system_cli() {
  _run_device_cmd_as_user_w_tty_w_args "root" "nixos-sf-device-system-config-update" "$@"
}

update_device_system_now_cli() {
  _run_device_cmd_as_user_w_tty_w_args "root" "nixos-sf-device-system-config-update-now" "$@"
}

update_device_system_fetch_and_build_only() {
  _run_device_cmd_as_user_w_tty_w_args "root" "nixos-sf-device-system-config-update-fetch-and-build-system-closure-only" "$@"
}


build_device_system_update_bundle_locally_cli() {
  # TODO:

  local device_id
  device_id="$(get_required_current_device_id)" || return 1
  local cfg_root_dir
  cfg_root_dir="$(get_device_cfg_repo_root_dir)" || return 1

  export "NIXOS_DEVICE_IDENTIFIER_OVERRIDE=$device_id"
  export "NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_FETCHED_SRC_OVERRIDE=$cfg_root_dir"

  local system_cfg_up_dir
  local system_config_dir_inner_1
  local system_config_src_dir_inner_2
  _build_system_config_dir_update "system_cfg_up_dir" "system_config_dir_inner_1" "system_config_src_dir_inner_2"
  echo "system_config_src_dir='$system_config_src_dir_inner_2'"
  echo "system_config_dir='$system_config_dir_inner_1'"
  echo "system_cfg_up_dir='$system_cfg_up_dir'"
}


build_device_system_update_bundle_locally_and_deploy_cli() {
  1>&2 echo "ERROR: TODO: Implement!"
  false
}
