#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_info_store.sh
. "$common_factory_install_sh_lib_dir/app_factory_info_store.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_git.sh
. "$common_factory_install_sh_lib_dir/app_factory_git.sh"


init_factory_state_cli() {
  print_title_lvl1 "Intializing factory state."
  init_factory_state "$@"

  print_title_lvl1 "Checking for other required states."
  configure_git_minimally
}
