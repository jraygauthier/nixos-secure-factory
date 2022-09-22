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
