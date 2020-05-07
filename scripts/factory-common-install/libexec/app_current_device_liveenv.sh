#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-sf-factory-common-install-get-libexec-dir)"
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



are_liveenv_nixos_partitions_already_mounted() {
  run_cmd_as_device_root "liveenv-nixos-partition-already-mounted"
}

mount_liveenv_nixos_partitions() {
  print_title_lvl1 "Mounting nixos partitions in the liveenv"
  run_cmd_as_device_root "liveenv-nixos-partition-mount"
}


umount_liveenv_nixos_partitions() {
  print_title_lvl1 "Unmounting nixos partitions in the liveenv"
  run_cmd_as_device_root "liveenv-nixos-partition-umount"
}

mount_livenv_nixos_partition_if_required() {
  print_title_lvl1 "Mounting nixos partitions in the liveenv if required"
  if are_liveenv_nixos_partitions_already_mounted; then
    echo "Partitions already mounted."
    return 0
  fi
  run_cmd_as_device_root "liveenv-nixos-partition-mount"
}