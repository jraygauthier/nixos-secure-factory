#!/usr/bin/env bash
common_libexec_dir="$(pkg-nixos-common-get-libexec-dir)"
. "$common_libexec_dir"/permissions.sh

common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/git.sh"


# permissions

create_and_assign_proper_permissions_to_gopass_home_dir_lazy_and_silent() {
  local target_gopass_home_dir="$1"
  create_and_assign_proper_permissions_to_dir_lazy "$target_gopass_home_dir" "700"
  create_and_assign_proper_permissions_to_dir_lazy "$target_gopass_home_dir/.config" "755"
}


get_gopass_sandbox_dir() {
  # TODO: Defaults to '~/.nixos-secure-factory/.gnupg'
  local ws_dir
  ws_dir="$(get_nixos_secure_factory_workspace_dir)"
  local default_sandbox_gopass_home_dir="$ws_dir/.gopass-home"

  local gopass_home_sanbox_dir="${PKG_NIXOS_FACTORY_COMMON_INSTALL_SANDBOXED_GOPASS_HOME_DIR:-$default_sandbox_gopass_home_dir}"
  echo "$gopass_home_sanbox_dir"
}


is_gopass_home_sandboxed() {
  local gopass_home_sanbox_disable_value="${PKG_NIXOS_FACTORY_COMMON_INSTALL_SANDBOXED_GOPASS_HOME_DISABLE:-0}"
  # 1>&2 echo "gopass_home_sanbox_disable_value='$gopass_home_sanbox_disable_value'"
  ! test "1" == "${gopass_home_sanbox_disable_value:-0}"
}


get_gopass_home_dir() {
  if is_gopass_home_sandboxed; then
    # 1>&2 echo "get_gopass_home_dir -> sandboxed"
    local sandbox_gopass_home_dir
    sandbox_gopass_home_dir="$(get_gopass_sandbox_dir)"
    create_and_assign_proper_permissions_to_gopass_home_dir_lazy_and_silent "$sandbox_gopass_home_dir"
    echo "$sandbox_gopass_home_dir"
  else
    # 1>&2 echo "get_gopass_home_dir -> not sandboxed"
    echo "$HOME"
  fi
}


run_sandboxed_gopass() {
  local gpg_home_dir
  gpg_home_dir="$(get_default_gpg_home_dir)" || return 1

  local gopass_home_dir
  gopass_home_dir="$(get_gopass_home_dir)" || return 1

  ensure_minimal_git_config_error_if_not || return 1

  GOPASS_HOMEDIR="$gopass_home_dir" \
  GOPASS_CONFIG="$gopass_home_dir/.config/gopass/gopass.yaml" \
  GNUPGHOME="$gpg_home_dir" \
    nix-gopass "$@"
}


configure_gopass_store() {
  local store_id="$1"
  run_sandboxed_gopass config --store "$store_id" autosync false
  run_sandboxed_gopass config --store "$store_id" autoimport false

  # TODO: Consider this.
  run_sandboxed_gopass config --store "$store_id" check_recipient_hash false

  run_sandboxed_gopass config --store "$store_id" noconfirm true
  run_sandboxed_gopass config --store "$store_id" nopager true
  # run_sandboxed_gopass config --store "$store_id" nocolor true

  run_sandboxed_gopass config --store "$store_id" askformore false
  run_sandboxed_gopass config --store "$store_id" notifications false
  run_sandboxed_gopass config --store "$store_id" safecontent false
}


configure_gopass_root_store() {
  store_id=""
  run_sandboxed_gopass config --store "$store_id" autosync false
  run_sandboxed_gopass config --store "$store_id" autoimport false
}
