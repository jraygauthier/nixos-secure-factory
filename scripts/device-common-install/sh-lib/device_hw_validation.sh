#!/usr/bin/env bash
declare device_common_install_sh_lib_dir
device_common_install_sh_lib_dir="$(pkg-nsf-device-common-install-get-sh-lib-dir)"
. "$device_common_install_sh_lib_dir/block_device_info.sh"


is_expected_hdd() {
  local expected_value
  expected_value="${1?ERROR variables is unset}"

  local tolerance
  tolerance="${2?ERROR variable is unset}"

  local lower_bound
  hdd_lower_bound=$(echo "($1 - $2)" | bc -l)

  local hdd_upper_bound
  hdd_upper_bound=$(echo "($1 + $2)" | bc -l)

  declare block_device
  block_device="$(get_block_device_for_partition "/dev/disk/by-label/nixos")"

  local hdd_size
  hdd_size="$(lsblk "$block_device" | head -n 2 | tail -n 1 | awk '{print $4}' | sed 's/[A-Z]//g')"

  if [ "1" -eq "$(echo "${hdd_size} >= ${hdd_lower_bound}" | bc -l)" ] && \
     [ "1" -eq "$(echo "${hdd_size} <= ${hdd_upper_bound}" | bc -l)" ]; then
     return 0
  else
    return 1
  fi

  # This point should never be reached.
  return 1
}

is_expected_ram() {
  local expected_value
  expected_value="${1?ERROR variables is unset}"

  local tolerance
  tolerance="${2?ERROR variable is unset}"

  local ram_lower_bound
  ram_lower_bound=$(echo "($expected_value - $tolerance)" | bc -l)

  local ram_upper_bound
  ram_upper_bound=$(echo "($expected_value + $tolerance)" | bc -l)

  local ram_size
  ram_size="$(free -m --si | grep Mem: | awk '{print $2}')"
  if [ 1 -eq $(echo "${ram_size} >= ${ram_lower_bound}" | bc -l) ] && \
     [ 1 -eq $(echo "${ram_size} <= ${ram_upper_bound}" | bc -l) ]; then
     return 0
  else
    return 1
  fi

  # This point should never be reached.
  return 1
}

ensure_expected_device() {
  local hw_config_yaml_str
  hw_config_yaml_str="${1?ERROR variables is unset}"

  local network_interface
  network_interface="${2?ERROR variable is unset}"

  local device
  device="${3?ERROR variable is unset}"

  local device_mac
  device_mac=$(ifconfig "$network_interface" | grep ether | awk '{print $2}')

  local key
  if ! echo "$hw_config_yaml_str" | yq -e --arg key "$device_mac" '.[$key]' > /dev/null; then
    key="default"
  else
    key="$device_mac"
  fi

  local expected_value
  expected_value="$(echo "$hw_config_yaml_str" | yq -e -j --arg key "$key" \
                                           --arg dev "$device" \
                                           '.[$key][$dev].size')"

  local tolerance
  tolerance="$(echo "$hw_config_yaml_str" | yq -e -j --arg key "$key" \
                                      --arg dev "$device" \
                                      '.[$key][$dev].tolerance')"

  if [ null == "$expected_value" ] || [ null == "$tolerance" ];then
    1>&2 printf "ERROR: Could not read specification from \n $hw_config_yaml_str \n"
    return 1
  fi

  if [ "$device" == ram ]; then
    if ! is_expected_ram "$expected_value" "$tolerance"; then
      1>&2 echo "ERROR: $device size is out of range, expecting $expected_value"
      return 1
    fi
  else
    if ! is_expected_hdd "$expected_value" "$tolerance"; then
      1>&2 echo "ERROR: $device size is out of range, expecting $expected_value"
      return 1
    fi
  fi
}
