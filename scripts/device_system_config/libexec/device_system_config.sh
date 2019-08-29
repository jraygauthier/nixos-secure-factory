#!/usr/bin/env bash

build_device_config() {
  local out_var_name="$1"
  local config_filename="$2"
  local device_id="$3"

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/system"

  nix build --out-link "$outLink" \
    -f "$config_filename" \
    --argstr device_identifier "$device_id" \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }

  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
}


get_device_config_etc_dir() {
  echo "/etc/nixos-device-system-config"
}


get_device_config_etc_nix_search_path_dir() {
  echo "$(get_device_config_etc_dir)/nix-search-path"
}


# shellcheck disable=2120 # Optional arguments.
build_device_config_system_closure() {
  local out_var_name="$1"
  local cfg_closure="$2"

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/system"

  searchPathArgs=()
  while read -r path; do
    local pathName
    pathName="$(basename "$path")"
    searchPathArgs+=( "-I" "$pathName=$path" )
  done < <(find "${cfg_closure}$(get_device_config_etc_nix_search_path_dir)" -mindepth 1 -maxdepth 1)

  nix build \
    --out-link "$outLink" \
    -I "nixos-config=${cfg_closure}$(get_device_config_etc_dir)/configuration.nix" \
    "${searchPathArgs[@]}" \
    -f "${cfg_closure}$(get_device_config_etc_nix_search_path_dir)/nixos" system \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
}
