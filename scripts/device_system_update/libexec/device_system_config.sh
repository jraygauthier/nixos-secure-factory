#!/usr/bin/env bash

build_device_config() {
  print_title_lvl2 "Building device configuration"

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


# shellcheck disable=2120 # Optional arguments.
build_device_config_system_closure() {
  print_title_lvl2 "Building device configuration system closure"
  local out_var_name="$1"
  local cfg_closure="$2"

  local tmpdir
  tmpdir="$(mktemp -d)"

  local outLink="$tmpdir/system"

  nix build \
    --out-link "$outLink" \
    -I "nixpkgs=${cfg_closure}/nixpkgs_src" \
    -I "nixos-config=${cfg_closure}/configuration.nix" \
    -f "${cfg_closure}/nixos_src" system \
    || { rm -rf "$tmpdir"; return 1; }

  local out_val
  out_val=$(readlink -f "$outLink") \
    || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"

  eval "$out_var_name='$out_val'"
}


install_system_closure_to_device() {
  print_title_lvl2 "Installing system closure on device"
  local system_closure="$1"

  local profile=/nix/var/nix/profiles/system
  local profile_name="system"
  # local action="test"
  # local action="dry-activate"
  local action="switch"
  if [ "$profile_name" != system ]; then
    profile="/nix/var/nix/profiles/system-profiles/$1"
    mkdir -p -m 0755 "$(dirname "$profile")"
  fi

  local cmd
  cmd=$(cat <<EOF
nix-env -p "$profile" --set "$system_closure"
EOF
)
  run_cmd_as_device_root "$cmd"

  local cmd2
  cmd2=$(cat <<EOF
$system_closure/bin/switch-to-configuration "$action" || \
  { echo "warning: error(s) occurred while switching to the new configuration" >&2; exit 1; }
EOF
)

  run_cmd_as_device_root "$cmd2"
}
