#!/usr/bin/env bash
# common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# From dependency libs.
common_install_sh_lib_dir="$(pkg-nsf-common-install-get-sh-lib-dir)"
# shellcheck source=mount.sh
. "$common_install_sh_lib_dir/mount.sh"
