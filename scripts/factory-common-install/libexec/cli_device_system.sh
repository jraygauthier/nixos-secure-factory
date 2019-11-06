#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
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