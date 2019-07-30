#!/usr/bin/env bash
# device_common_install_libexec_dir="$(pkg_nixos_device_common_install_get_libexec_dir)"
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"
. "$common_install_libexec_dir/prettyprint.sh"

is_run_from_nixos_live_cd() {
  test "$(lsblk | grep sr0 | awk '{ print $7}')" == "/iso" && \
  test "$(lsblk | grep loop0 | awk '{ print $7}')" == "/nix/.ro-store"
}

ensure_run_from_nixos_live_cd() {
  is_run_from_nixos_live_cd || \
    { 1>&2 echo "ERROR: This script should be run only from nixos livecd."; exit 1; }
}


