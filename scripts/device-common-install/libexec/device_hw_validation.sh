#!/usr/bin/env bash

is_expected_hdd() {
  local expected_value
  local tolerance

  expected_value="${1?ERROR variables is unset}"
  tolerance="${2?ERROR variable is unset}"

  hdd_lower_bound=$(expr "$1" - "$2")
  hdd_upper_bound=$(expr "$1" + "$2")
  hdd_size="$(lsblk /dev/sda | head -n 2 | tail -n 1 | awk '{print $4}' | sed 's/[A-Z]//g')"

  test "$hdd_size" -ge "$hdd_lower_bound" && test "$hdd_size" -le "$hdd_upper_bound"
}

is_expected_ram() {
  local expected_value
  local tolerance

  expected_value="${1?ERROR variables is unset}"
  tolerance="${2?ERROR variable is unset}"

  ram_lower_bound=$(expr "$1" - "$2")
  ram_upper_bound=$(expr "$1" + "$2")
  ram_size="$(free -m --si | grep Mem: | awk '{print $2}')"

  test "$ram_size" -ge "$ram_lower_bound" && test "$ram_size" -le "$ram_upper_bound"
}

ensure_expected_device() {
  local hw_config
  local key
  local expected_value
  local tolerance
  local module
  local device

  hw_config="${1?ERROR variables is unset}"
  network_interface="${2?ERROR variable is unset}"
  device="${3?ERROR variable is unset}"

  device_mac=$(ifconfig "$network_interface" | grep ether | awk '{print $2}')

  if [ null == "$(echo "$hw_config" | yq --arg key "$device_mac" '.[$key]')" ]; then
    key="default"
  else
    key="$device_mac"
  fi

  expected_value="$(echo "$hw_config" | yq --arg key "$device_mac" \
                                           --arg dev "$device" \
                                           '.[$key][$dev].size')"
  tolerance="$(echo "$hw_config" | yq --arg key "$device_mac" \
                                      --arg dev "$device" \
                                      '.[$key][$dev].tolerance')"

  if [ null == $expected_value ] || [ null == $tolerance ];then
    1>&2 printf "ERROR: Could not read specification from \n $hw_config \n"
    return 1
  fi

  if [ "$device" == ram ]; then
    if ! is_expected_ram $expected_value $tolerance; then
      1>&2 echo "ERROR: $device size is out of range, expecting $expected_value"
      return 1
    fi
  else
    if ! is_expected_hdd $expected_value $tolerance; then
      1>&2 echo "ERROR: $device size is out of range, expecting $expected_value"
      return 1
    fi
  fi

  return 0
}
