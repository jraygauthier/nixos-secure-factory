#!/usr/bin/env bash

common_install_sh_lib_dir="$(pkg-nixos-sf-common-install-get-sh-lib-dir)"
# shellcheck source=prettyprint.sh
. "$common_install_sh_lib_dir/prettyprint.sh"

# The following tools are based on 'factory-nix-src-update' executable
# instead of 'nix_src_update.sh' in order to encapsulate dependencies
# required to implements the pin update tools.

update_pinned_nix_src_by_name() {
  local pinned_src_root_dir="${1?}"
  local src_name="${2?}"
  local src_channel="${3:-default}"

  print_title_lvl2 "Updating pinned nix src '$src_name' at channel '$src_channel'."

  local channel_in_fp_prefix="$pinned_src_root_dir/$src_name/channel/${src_channel}.in"
  local channel_in_yaml_fp="${channel_in_fp_prefix}.yaml"
  local channel_in_json_fp="${channel_in_fp_prefix}.json"

  local channel_in_yaml_or_json_fp="$channel_in_json_fp"
  if [[ -f "$channel_in_yaml_fp" ]]; then
    channel_in_yaml_or_json_fp="$channel_in_yaml_fp"
  fi

  local channel_out_json_fp="$pinned_src_root_dir/$src_name/channel/${src_channel}.json"

  factory-nix-src-update "$channel_in_yaml_or_json_fp" "$channel_out_json_fp"
}


update_pinned_nix_srcs_by_names() {
  local pinned_src_root_dir="${1?}"
  shift 1

  local pinned_srcs_a=( "$@" )
  if [[ "${#pinned_srcs_a[@]}" -eq "0" ]]; then
    1>&2 echo "ERROR: No pinned sourced passed as input."
    return 1
  fi

  local pinned_src_name_w_opt_channel
  while read -r pinned_src_name_w_opt_channel; do
    local src_name
    src_name="$(echo "$pinned_src_name_w_opt_channel" | awk -F':' '{ print $1 }')"
    local specified_channel
    specified_channel="$(echo "$pinned_src_name_w_opt_channel" | awk -F':' '{ print $2 }')"

    update_pinned_nix_src_by_name "$pinned_src_root_dir" "$src_name" "$specified_channel"
  done < <(printf "%s\n" "${pinned_srcs_a[@]}")
}


update_pinned_nix_srcs_all() {
  # TODO: Take an optional warn on error which will continue even though an error is
  #       detected for a particular source instead of failing.
  # TODO: Take a list of channel to update. Otherwise, update the default channel only.
  local pinned_src_root_dir="${1?}"
  shift 1

  printf "The following sources/channels will be updated:\n\n"
  local all_nix_srcs=()
  while read -r pinned_rd; do
    local pinned_src_name
    pinned_src_name="$(basename "$pinned_rd")"
    local pinned_src_channel="default"
    local pinned_src="${pinned_src_name}:${pinned_src_channel}"
    echo "$pinned_src"
    all_nix_srcs+=( "$pinned_src" )
  done < <(find "$pinned_src_root_dir" -maxdepth 1 -mindepth 1)

  printf "\n"

  update_pinned_nix_srcs_by_names "$pinned_src_root_dir" "${all_nix_srcs[@]}"
}
