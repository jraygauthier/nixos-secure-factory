#!/usr/bin/env bash

common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
. "$common_factory_install_sh_lib_dir/nix_src_update_helpers.sh"

factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-install-get-sh-lib-dir)"
. "$factory_install_sh_lib_dir/workspace_paths.sh"


update_factory_install_pinned_nix_srcs() {
  local factory_install_repo_root_dir
  factory_install_repo_root_dir="$(get_writable_factory_install_repo_root_dir)" || return 1

  local pinned_src_root_dir="$factory_install_repo_root_dir/pkgs/pinned-src"
  update_pinned_nix_srcs_by_names "$pinned_src_root_dir" "$@"
}


update_factory_install_pinned_nix_srcs_all_cli() {
  local factory_install_repo_root_dir
  factory_install_repo_root_dir="$(get_writable_factory_install_repo_root_dir)" || return 1

  local pinned_src_root_dir="$factory_install_repo_root_dir/pkgs/pinned-src"

  print_title_lvl1 "Updating all device os config pinned nix srcs under '$pinned_src_root_dir'."
  update_pinned_nix_srcs_all "$pinned_src_root_dir" "$@"
}


update_factory_install_pinned_nix_srcs_sf_ssh_auth_repo_cli() {
  local channel="${1:-default}"
  local src_w_channel="nixos-sf-ssh-auth:${channel}"
  print_title_lvl1 "Updating device os config pinned '$src_w_channel' src."
  update_factory_install_pinned_nix_srcs "$src_w_channel"
}


update_factory_install_pinned_nix_srcs_sf_shell_complete_repo_cli() {
  local channel="${1:-default}"
  local src_w_channel="nixos-sf-shell-complete:${channel}"
  print_title_lvl1 "Updating device os config pinned '$src_w_channel' src."
  update_factory_install_pinned_nix_srcs "$src_w_channel"
}


update_factory_install_pinned_nix_srcs_cli() {
  local src_list_str="$*"
  print_title_lvl1 "Updating specific device os config pinned nix srcs: '$src_list_str'."
  update_factory_install_pinned_nix_srcs "$@"
}
