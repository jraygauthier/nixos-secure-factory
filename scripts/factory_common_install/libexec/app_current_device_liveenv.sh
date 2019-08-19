#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
# Source all dependencies:
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/app_current_device_ssh.sh"


is_device_run_from_nixos_liveenv() {
  local cmd
  cmd=$(cat <<'EOF'
lsblk | awk '{ print $7}' | grep -q "/iso" && \
test "$(lsblk | grep loop0 | awk '{ print $7}')" == "/nix/.ro-store"
EOF
)
  run_cmd_as_device_root "$cmd"
}





mount_liveenv_nixos_partitions() {
  print_title_lvl1 "Mounting nixos partitions in the liveenv"
  run_cmd_as_device_root "liveenv_mount_nixos_partition"
}


umount_liveenv_nixos_partitions() {
  print_title_lvl1 "Unmounting nixos partitions in the liveenv"
  run_cmd_as_device_root "liveenv_umount_nixos_partition"
}