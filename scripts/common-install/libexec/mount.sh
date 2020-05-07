#!/usr/bin/env bash
common_install_libexec_dir="$(pkg-nixos-sf-common-install-get-libexec-dir)"


# shellcheck source=prettyprint.sh
. "$common_install_libexec_dir/prettyprint.sh"

_sudo_exec() {
  if command -v sudo &> /dev/null && echo ok; then
    sudo "$@"
  else
    # When not present, we assume we're already root and attempt
    # normal execution.
    local actual_cmd="$1"
    shift
    $actual_cmd "$@"
  fi
}


mount_secure_ramfs() {
  local ramfs_mount_dir="$1"
  local dir_owner
  dir_owner="$(logname)"
  local size="1M"

  print_title_lvl1 "Mounting secure ramfs space"

  ! mountpoint -q "$ramfs_mount_dir" || \
    { echo "WARNING: Ramfs space already mounted at: '$ramfs_mount_dir'"; return 1; }

  echo "rm -rf '$ramfs_mount_dir'"
  _sudo_exec rm -rf "$ramfs_mount_dir"
  echo "mkdir -m 0700 '$ramfs_mount_dir'"
  mkdir -m 0700 "$ramfs_mount_dir"
  echo "Secure dir '$ramfs_mount_dir' successfully created."
  _sudo_exec mount -t ramfs -o size="$size" ramfs "$ramfs_mount_dir"
  _sudo_exec chmod 0700 "$ramfs_mount_dir"
  _sudo_exec chown "$(logname)" "$ramfs_mount_dir"
  echo "Secure ramfs space successfully mounted at: '$ramfs_mount_dir'."
  echo " -> Owner is '$dir_owner'"
  echo " -> Size is '$size'"
  # TODO: Encrypt as well?

  find "$ramfs_mount_dir" -exec stat -c '%a %n' {} +
}


umount_secure_ramfs() {
  ramfs_mount_dir="$1"

  print_title_lvl1 "Unmounting secure ramfs space"

  mountpoint -q "$ramfs_mount_dir" || \
    { echo "WARNING: No secure ramfs space to unmount at: '$ramfs_mount_dir'"; return 1; }

  _sudo_exec umount "$ramfs_mount_dir"
  echo "Secure ramfs space successfully unmounted from: '$ramfs_mount_dir'."
  rmdir "$ramfs_mount_dir"
  echo "Secure dir '$ramfs_mount_dir' successfully unmounted."
}
