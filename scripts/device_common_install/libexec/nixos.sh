#!/usr/bin/env bash
# device_common_install_libexec_dir="$(pkg_nixos_device_common_install_get_libexec_dir)"
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"
. "$common_install_libexec_dir/mount.sh"


ensure_nixos_partition_mounted() {
  if ! mountpoint -q /mnt; then
    echo "ERROR: Nixos partition should be mounted on \`/mnt\` for this script to work."
    exit 1
  fi
}