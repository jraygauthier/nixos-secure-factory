#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_gopass_vaults_ro.sh
. "$common_factory_install_sh_lib_dir/app_current_device_gopass_vaults_ro.sh"


print_device_root_user_ssh_public_key() {
  local store_key
  store_key="$(get_rel_root_user_ssh_rsa_public_key)" || return 1
  cat_gopass_device_bin_secret "$store_key"
}


print_device_host_ssh_public_key() {
  local store_key
  store_key="$(get_rel_host_ssh_public_key_for_key_type "$@")" || return 1
  cat_gopass_device_bin_secret "$store_key"
}


get_by_ref_device_host_ssh_public_key() {
  local _out_vn="${1?}"
  local kt="${2:-}"

  local store_key
  store_key="$(get_rel_host_ssh_public_key_for_key_type "$kt")" || return 1
  get_by_ref_gopass_device_bin_secret "$_out_vn" "$store_key"
}


copy_device_ssh_identity_to_clipboard_cli() {
  print_title_lvl1 "Copying current device ssh identity (root public key) to your clipboard"
  local store_key
  store_key="$(get_rel_root_user_ssh_rsa_public_key)"

  local full_store_key
  full_store_key="$(get_gopass_device_full_store_key_for "$store_key")"

  cat_gopass_device_bin_secret "$store_key" \
    | DISPLAY="${DISPLAY:-":0"}" xclip -selection clipboard
  echo "Device public key at '$full_store_key' has been placed in your clipboard. Paste it where you need."
}
