#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
. "$common_factory_install_sh_lib_dir/workspace_paths.sh"


get_writable_factory_install_repo_root_dir() {
  local ws_dir
  ws_dir="$(pkg-nsf-factory-install-get-repo-root-dir)"

  if ! [[ -w "$ws_dir" ]]; then
    1>&2 echo "ERROR: ${FUNCNAME[0]}: factory install repository root dir at '$ws_dir' is not writable as expected."
    return 1
  fi

  echo "$ws_dir"
}
