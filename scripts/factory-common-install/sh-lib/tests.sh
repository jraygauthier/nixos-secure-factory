#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"

# TODO: Replace all this by a pytest test.

TESTED_PACKAGE_NAME="nsf-factory-common-install"

_list_all_modules() {
  find "$common_factory_install_sh_lib_dir" -mindepth 1 -maxdepth 1 -name '*.sh'
}


printf -- "Sourcing all modules from %s\n" "$TESTED_PACKAGE_NAME"
printf -- "=========================================\n\n"
# Source all modules.
for m in $(_list_all_modules); do
  # Avoid circular dependency.
  if ! [[ "$m" == "$common_factory_install_sh_lib_dir/tests.sh" ]]; then
    echo "Sourcing module '$m'"
    # shellcheck disable=SC1090  # By design.
    . "$m"
  fi
done

printf -- "\n"
printf -- "Everything was sourced successfully"
printf -- "\n\n"

launch_all_tests() {

  printf -- "Launching all tests for %s\n" "$TESTED_PACKAGE_NAME"
  printf -- "===============================================\n\n"

  local factory_common_install_pkg_root_dir
  factory_common_install_pkg_root_dir="$(pkg-nsf-factory-common-install-get-root-dir)"

  "$factory_common_install_pkg_root_dir/enter-build-env.sh" \
    --run "pytest \"$factory_common_install_pkg_root_dir/tests/lib\""

  pytest "$factory_common_install_pkg_root_dir/tests/installed"
}
