#!/usr/bin/env bash

get_device_config_etc_dir() {
  echo "/etc/nixos-device-system-config"
}


get_device_config_etc_nix_search_path_dir() {
  echo "$(get_device_config_etc_dir)/nix-search-path"
}


get_search_path_srcs_from_system_cfg_dir() {
  local system_cfg_dir="$1"
  find "${system_cfg_dir}$(get_device_config_etc_nix_search_path_dir)" -mindepth 1 -maxdepth 1
}


build_nix_search_path_args_from_search_path_srcs() {
  # Use name ref for the output.
  local -n out_array="$1"
  local search_path_srcs="$2"

  out_array=()
  while read -r path; do
    local pathName
    pathName="$(basename "$path")"
    out_array+=( "-I" "$pathName=$path" )
  done < <(echo "$search_path_srcs")
}


build_nix_search_path_args_from_system_cfg_dir() {
  local out_array_var_name="$1"
  local system_cfg_dir="$2"

  local search_path_srcs
  search_path_srcs="$(get_search_path_srcs_from_system_cfg_dir "$system_cfg_dir")"

  build_nix_search_path_args_from_search_path_srcs "$out_array_var_name" "$search_path_srcs"
}


# TODO: Move into a more generic pkg / module.
build_nixos_config_dir() {
  echo "build_nixos_config_dir begin"
  local out_var_name="$1"
  local config_filename="$2"
  shift
  shift
  # Remaing arguments passed directly to 'nix build'.

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/nixos_config_dir"

  nix build \
    --out-link "$outLink" \
    -f "$config_filename" \
    "$@" \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }

  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
  echo "build_nixos_config_dir end"
}


build_device_config_dir() {
  echo "build_device_config_dir begin"
  local out_var_name="$1"
  local config_filename="$2"
  local device_id="$3"
  shift
  shift
  shift
  # Remaing arguments passed directly to 'nix build'.

  build_nixos_config_dir "$out_var_name" "$config_filename" \
    --argstr device_identifier "$device_id" \
    "$@"

  echo "build_device_config_dir end"
}


# shellcheck disable=2120 # Optional arguments.
build_device_config_system_closure() {
  echo "build_device_config_system_closure begin"
  local out_var_name="$1"
  local system_cfg_dir="$2"
  shift 2
  # Remaing arguments passed directly to 'nix build'.

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/system"

  local search_path_args=()
  build_nix_search_path_args_from_system_cfg_dir "search_path_args" "$system_cfg_dir"

  # The nixos's nixpkgs sources (nixos channel).
  local nixos_src
  nixos_src="${system_cfg_dir}$(get_device_config_etc_nix_search_path_dir)/nixos"

  nix build \
    --out-link "$outLink" \
    -I "nixos-config=${system_cfg_dir}$(get_device_config_etc_dir)/configuration.nix" \
    "${search_path_args[@]}" \
    "$@" \
    -f "$nixos_src/nixos" system \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
  echo "build_device_config_system_closure end"
}
