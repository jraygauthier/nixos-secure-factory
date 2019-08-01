#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
# Source all dependencies:
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/app_current_device_ssh.sh"


mount_liveenv_nixos_partitions() {
  print_title_lvl1 "Mounting nixos partitions in the liveenv"
  run_cmd_as_device_root "liveenv_mount_nixos_partition"
}


umount_liveenv_nixos_partitions() {
  print_title_lvl1 "Unmounting nixos partitions in the liveenv"
  run_cmd_as_device_root "liveenv_umount_nixos_partition"
}