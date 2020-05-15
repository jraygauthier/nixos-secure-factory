#!/usr/bin/env bash
nsf_pin_sh_lib_dir="$(pkg-nsf-pin-get-sh-lib-dir)"
. "$nsf_pin_sh_lib_dir/nix_src_update_helpers.sh"

common_install_sh_lib_dir="$(pkg-nixos-sf-common-install-get-sh-lib-dir)"
. "$common_install_sh_lib_dir/prettyprint.sh"

common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
. "$common_factory_install_sh_lib_dir/workspace_paths.sh"


update_device_os_cfg_pinned_nix_srcs() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_writable_device_cfg_repo_root_dir)" || return 1

  local pinned_src_root_dir="$device_cfg_repo_root_dir/.nix/pinned-src"
  update_pinned_nix_srcs_by_names "$pinned_src_root_dir" "$@"
}


update_device_os_cfg_pinned_nix_srcs_all_cli() {
  local device_cfg_repo_root_dir
  device_cfg_repo_root_dir="$(get_writable_device_cfg_repo_root_dir)" || return 1

  local pinned_src_root_dir="$device_cfg_repo_root_dir/.nix/pinned-src"

  print_title_lvl1 "Updating all device os config pinned nix srcs under '$pinned_src_root_dir'."
  update_pinned_nix_srcs_all "$pinned_src_root_dir" "$@"
}


update_device_os_cfg_pinned_nix_srcs_nixpkgs_cli() {
  local channel="${1:-default}"
  local src_w_channel="nixpkgs:${channel}"
  print_title_lvl1 "Updating device os config pinned '$src_w_channel' src."
  update_device_os_cfg_pinned_nix_srcs "$src_w_channel"
}

update_device_os_cfg_pinned_nix_srcs_sf_cli() {
  local channel="${1:-default}"
  local src_w_channel="nixos-secure-factory:${channel}"
  print_title_lvl1 "Updating device os config pinned '$src_w_channel' src."
  update_device_os_cfg_pinned_nix_srcs "$src_w_channel"
}

update_device_os_cfg_pinned_nix_srcs_sf_pin_cli() {
  local channel="${1:-default}"
  local src_w_channel="nsf-pin:${channel}"
  print_title_lvl1 "Updating device os config pinned '$src_w_channel' src."
  update_device_os_cfg_pinned_nix_srcs "$src_w_channel"
}


update_device_os_cfg_pinned_nix_srcs_cli() {
  local src_list_str="$*"
  print_title_lvl1 "Updating specific device os config pinned nix srcs: '$src_list_str'."
  update_device_os_cfg_pinned_nix_srcs "$@"
}
