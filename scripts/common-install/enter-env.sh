#!/usr/bin/env bash
set -euf -o pipefail
script_dir=`cd "$(dirname $0)" > /dev/null;pwd`
factory_install_repo_root_dir=`cd "$(dirname $0)/../.." > /dev/null;pwd`

# Should help with developping scripts.
scripts_dir="$factory_install_repo_root_dir/scripts"
export PKG_NSF_COMMON_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common"
export PKG_NSF_COMMON_INSTALL_DEV_OVERRIDE_ROOT_DIR="$scripts_dir/common-install"

# nix-shell $script_dir/env.nix "$@"
nix-shell -p "import $script_dir/env.nix {}" "$@"