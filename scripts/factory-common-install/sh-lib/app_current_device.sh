#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# Source both dependencies.
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/ssh.sh
. "$common_factory_install_sh_lib_dir/ssh.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_ssh.sh
. "$common_factory_install_sh_lib_dir/app_current_device_ssh.sh"


