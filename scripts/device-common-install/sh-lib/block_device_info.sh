#!/usr/bin/env bash

get_device_partition_by_1b_index() {
  declare device="${1?}"
  declare partition_1b_index="${2?}"

  declare device_bn
  device_bn=$(basename "${device}")

  if echo "$device_bn" | grep -q -E '^nvme'; then
    # New naming scheme for SDD devices.
    echo "${device}p${partition_1b_index}"
  else
    # Old naming scheme for HDD devices.
    echo "${device}${partition_1b_index}"
  fi
}


get_block_device_for_partition() {
  declare partition="${1?}"
  if ! [[ -e "$partition" ]]; then
    1>&2 echo "ERROR: partition at '$partition' does not exists!"
    return 1
  fi

  declare block_device_name
  block_device_name="$(lsblk -no pkname "$partition" | head -n1)"
  if [[ -z "$block_device_name" ]] || ! [[ -e "/dev/$block_device_name" ]]; then
    1>&2 echo "ERROR: cannot retrieve 'pkname' for partition '$partition'."
    1>&2 echo " -> Most likely not a partition or potentially a virtual partition!"
    return 1
  fi
  echo "/dev/$block_device_name"
}


is_block_device_efi() {
  declare block_device="${1?}"
  if ! [[ -e "$block_device" ]]; then
    1>&2 echo "ERROR: block device at '$partition' does not exists!"
    return 1
  fi

  parted "$block_device" -- print | grep -q ESP
}


is_partition_on_efi_block_device() {
  declare partition="${1?}"
  declare block_device
  if ! block_device="$(get_block_device_for_partition "$partition")"; then
    return 1
  fi
  is_block_device_efi "$block_device"
}

