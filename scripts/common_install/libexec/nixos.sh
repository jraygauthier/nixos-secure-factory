#!/usr/bin/env bash

get_nixos_run_keys_dir() {
  echo "/run/keys"
}


is_run_keys_dir_available() {
  mountpoint -q "$(get_nixos_run_keys_dir)"
}


is_run_from_nixos_live_cd() {
  lsblk | awk '{ print $7}' | grep -q "/iso" && \
  test "$(lsblk | grep loop0 | awk '{ print $7}')" == "/nix/.ro-store"
}


ensure_run_from_nixos_live_cd() {
  is_run_from_nixos_live_cd || \
    { 1>&2 echo "ERROR: This script should be run only from nixos livecd."; exit 1; }
}


ensure_nixos_partition_mounted() {
  if ! mountpoint -q /mnt; then
    echo "ERROR: Nixos partition should be mounted on \`/mnt\` for this script to work."
    exit 1
  fi
}
