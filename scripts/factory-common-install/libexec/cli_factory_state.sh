#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"
. "$common_factory_install_libexec_dir/app_factory_git.sh"


init_factory_state_cli() {
  print_title_lvl1 "Intializing factory state."
  init_factory_state "$@"

  print_title_lvl1 "Checking for other required states."
  configure_git_minimally
}
