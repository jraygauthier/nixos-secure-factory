#!/usr/bin/env bash

device_system_update_libexec_dir="$(pkg-nixos-device-system-config-get-libexec-dir)"
. "$device_system_update_libexec_dir/device_system_config.sh"


_get_default_install_action() {
  echo "boot"
}


_get_sys_update_yaml_defaults_cfg_path() {
  local override_cfg
  if override_cfg="$(printenv "NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_CONFIG_DEFAULTS_YAML_OVERRIDE")"; then
    echo "$override_cfg"
    return 0
  fi

  local out_cfg_file="/etc/nixos-sf-device-system-config-updater/config-defaults.yaml"
  if ! [[ -f "$out_cfg_file" ]]; then
    1>&2 echo "ERROR: _get_sys_update_yaml_defaults_cfg_path: "
    1>&2 echo "  mandatory system update yaml cfg file does not exists at: '$out_cfg_file'."
    return 1
  fi
  echo "$out_cfg_file"
}


_get_sys_update_yaml_cfg_path() {
  local override_cfg
  if override_cfg="$(printenv "NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_CONFIG_YAML_OVERRIDE")"; then
    echo "$override_cfg"
    return 0
  fi

  local out_cfg_file="/etc/nixos-sf-device-system-config-updater/config.yaml"
  if ! [[ -f "$out_cfg_file" ]]; then
    return 1
  fi
  echo "$out_cfg_file"
}



_get_default_sys_update_cfg_value() {
  local jq_path="$1"

  local cfg_file
  cfg_file="$(_get_sys_update_yaml_defaults_cfg_path)" || return 1

  yq -e -j "$jq_path" \
    < "$cfg_file"
}


_get_sys_update_cfg_value() {
  local jq_path="$1"

  local cfg_file
  cfg_file="$(_get_sys_update_yaml_cfg_path)" || return 1

  yq -e -j "$jq_path" \
    < "$cfg_file"
}


_get_sys_update_cfg_value_or_default() {
  local jq_path="$1"

  local out_value
  if out_value="$(_get_sys_update_cfg_value "$jq_path")"; then
    echo "$out_value"
    return 0
  fi

  _get_default_sys_update_cfg_value "$jq_path"
}



_get_info_from_env_var_override_or_config_file() {
  local env_var_override="$1"
  local cfg_file_jq_path="$2"
  local info_desc="$3"
  local info_default_value="${4:-}"

  local info_from_env_override
  if info_from_env_override="$(printenv "$env_var_override")"; then
    echo "$info_from_env_override"
    return 0
  fi

  local info_from_cfg_file
  if info_from_cfg_file="$(_get_sys_update_cfg_value_or_default "$cfg_file_jq_path")"; then
    echo "$info_from_cfg_file"
    return 0
  fi

  if [[ -z "$info_default_value" ]]; then
    1>&2 echo "ERROR: Cannot retrieve *${info_desc}*"
    1>&2 echo "  either from env var override '$env_var_override'"
    1>&2 echo "  nor from config files: ['$(_get_sys_update_yaml_cfg_path)', '$(_get_sys_update_yaml_defaults_cfg_path)']"
    1>&2 echo "  at jq path '$cfg_file_jq_path'"
    return 1
  fi

  echo "$info_default_value"
}

format_ref_for_nix_prefetch() {
  local ref_name="$1"

  # When already has correct format, return as is.
  if echo "$ref_name" | grep -q -E "^refs/"; then
    echo "$ref_name"
    return 0
  fi

  # TODO: Check for valid ref format.

  # Assume refs/heads.
  echo "refs/heads/$ref_name"
}


format_rev_for_nix_prefetch() {
  local rev_id="$1"

  # TODO: Check for valid rev format.
  # Check for git sha or sha prefix of at least 10 characters.
  # if echo "$rev_id" | grep -q -E "^[0-9A-Fa-f]+$" \
  #     && test "${#rev_id}" -gt "10"; then
  #   echo "$rev_id"
  #   return 0
  # fi

  echo "$rev_id"
}


_get_system_update_device_id() {
  _get_info_from_env_var_override_or_config_file \
    "NIXOS_DEVICE_IDENTIFIER_OVERRIDE" \
    '."device-identifier"' \
    "device identifier"
}


_get_system_cfg_update_channel_type() {
  _get_info_from_env_var_override_or_config_file \
    "NIXOS_DEVICE_SYSTEM_CONFIG_CHANNEL_TYPE_OVERRIDE" \
    '.channel."system-config".type' \
    "device system config channel type"
}

_get_system_cfg_update_channel_url() {
  _get_info_from_env_var_override_or_config_file \
    "NIXOS_DEVICE_SYSTEM_CONFIG_CHANNEL_URL_OVERRIDE" \
    '.channel."system-config".url' \
    "device system config channel url"
}


_get_system_cfg_update_channel_ref() {
  local out_ref
  out_ref="$(_get_info_from_env_var_override_or_config_file \
    "NIXOS_DEVICE_SYSTEM_CONFIG_CHANNEL_REF_OVERRIDE" \
    '.channel."system-config".ref' \
    "device system config channel reference")" || return 1
  format_ref_for_nix_prefetch "$out_ref"
}


_get_system_cfg_update_channel_rev() {
  local out_ref
  out_ref="$(_get_info_from_env_var_override_or_config_file \
    "NIXOS_DEVICE_SYSTEM_CONFIG_CHANNEL_REV_OVERRIDE" \
    '.channel."system-config".rev' \
    "device system config channel revision")" || return 1
  format_rev_for_nix_prefetch "$out_ref"
}


# TODO: Common implementation shared with nix src updater.
_run_nix_prefetch_git() {
  local out_cfg_store_path_var_name="$1"
  local out_cfg_src_git_info_json_var_name="$2"
  local channel_url="$3"
  local channel_branch="$4"

  local fetch_cmd_store
  fetch_cmd_store=$(cat <<EOF
nix-prefetch-git \
  --url "$channel_url" \
  --rev "$channel_branch" \
  --no-deepClone
EOF
)

  # test -z "$prefetch_out"
  local prefetch_out
  if ! prefetch_out="$(2>&1 $fetch_cmd_store)"; then
    1>&2 echo "ERROR: Cannot fetch '$channel_url' repository content. Original error was:"
    1>&2 echo "$prefetch_out"
    exit 1
  fi

  echo "\`\`\`bash"
  echo "\$ $fetch_cmd_store"
  echo "$prefetch_out"
  echo "\`\`\`"

  local out_cfg_store_path
  out_cfg_store_path="$(echo "$prefetch_out" | grep "path is" | awk '{ print $3 }')"
  echo "out_cfg_store_path='$out_cfg_store_path'"

  local json_begin_ln
  json_begin_ln="$(echo "$prefetch_out" | grep -n -E '^{' | awk -F':' '{ print $1 }')"

  local json_to_eof
  json_to_eof="$(echo "$prefetch_out" | tail -n "+${json_begin_ln}")"

  local json_end_ln
  json_end_ln="$(echo "$json_to_eof" | grep -n -E '^}' | awk -F':' '{ print $1 }')"

  local out_cfg_src_git_info_json
  out_cfg_src_git_info_json="$(echo "$json_to_eof" | head -n "${json_end_ln}")"

  echo "out_cfg_src_git_info_json='$out_cfg_src_git_info_json'"

  eval "$out_cfg_store_path_var_name='$out_cfg_store_path'"
  eval "$out_cfg_src_git_info_json_var_name='$out_cfg_src_git_info_json'"
}


_fetch_current_system_config_repo() {
  local out_cfg_store_path_var_name="$1"
  local out_cfg_src_git_info_json_var_name="$2"

  local fetched_src_override="${NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_FETCHED_SRC_OVERRIDE:-}"
  if [[ -n "$fetched_src_override" ]] \
      && [[ -d "$fetched_src_override" ]]; then
    echo "Using NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_FETCHED_SRC_OVERRIDE='$fetched_src_override'."
    eval "$out_cfg_store_path_var_name='$fetched_src_override'"
    # TODO: We should output something sensible here.
    eval "$out_cfg_src_git_info_json_var_name=''"
    return 0
  fi

  local channel_url
  channel_url="$(_get_system_cfg_update_channel_url)" || return 1
  local channel_branch

  local channel_rev
  local channel_ref
  if channel_rev="$(_get_system_cfg_update_channel_rev 2> /dev/null)"; then
    channel_branch="$channel_rev"
  elif channel_ref="$(_get_system_cfg_update_channel_ref)"; then
    channel_branch="$channel_ref"
  else
    1>&2 echo "ERROR: _fetch_current_system_config_repo:"
    1>&2 echo "  missing either rev or ref from system config update channel."
    return 1
  fi


  _run_nix_prefetch_git \
    "$out_cfg_store_path_var_name" \
    "$out_cfg_src_git_info_json_var_name" \
    "$channel_url" \
    "$channel_branch"
}


_build_system_config_dir() {
  echo "_build_system_config_dir begin"
  local out_var_name="$1"
  local out_system_config_src_dir_var_name="$2"
  local config_name="release"

  local system_config_src_dir_inner_0
  local cfg_src_git_info_json
  _fetch_current_system_config_repo "system_config_src_dir_inner_0" "cfg_src_git_info_json"

  local built_dir_override="${NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_BUILT_DIR_OVERRIDE:-}"
  if [[ -n "$built_dir_override" ]] \
      && [[ -d "$built_dir_override" ]]; then
    echo "Using NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_BUILT_DIR_OVERRIDE='$built_dir_override'."
    eval "$out_var_name='$built_dir_override'"
    eval "$out_system_config_src_dir_var_name='$system_config_src_dir_inner_0'"
    return 0
  fi

  local device_id
  device_id="$(_get_system_update_device_id)" || return 1

  local config_filename="$system_config_src_dir_inner_0/${config_name}.nix"

  build_device_config_dir "$out_var_name" "$config_filename" "$device_id"
  eval "$out_system_config_src_dir_var_name='$system_config_src_dir_inner_0'"
  echo "_build_system_config_dir end"
}


_build_system_config_dir_update() {
  echo "_build_system_config_dir_update begin"
  local out_var_name="$1"
  local out_system_config_dir_var_name="$2"
  local out_system_config_src_dir_var_name="$3"
  local update_config_name="release"

  local system_config_dir_inner_0
  local system_config_src_dir_inner_1
  _build_system_config_dir "system_config_dir_inner_0" "system_config_src_dir_inner_1"

  local built_dir_up_override="${NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_BUILT_DIR_UPDATE_OVERRIDE:-}"
  if [[ -n "$built_dir_up_override" ]] \
      && [[ -d "$built_dir_up_override" ]]; then
    echo "Using NIXOS_DEVICE_SYSTEM_CONFIG_UPDATER_BUILT_DIR_UPDATE_OVERRIDE='$built_dir_up_override'."
    eval "$out_var_name='$built_dir_up_override'"
    eval "$out_system_config_dir_var_name='$system_config_dir_inner_0'"
    eval "$out_system_config_src_dir_var_name='$system_config_src_dir_inner_1'"
    return 0
  fi

  local device_id
  device_id="$(_get_system_update_device_id)" || return 1

  # device_system_cfg_channel_url
  # _get_system_cfg_update_channel_url
  # _get_system_cfg_update_channel_ref

  local update_config_filename
  update_config_filename="$system_config_dir_inner_0$(get_device_config_etc_dir)/device-update/${update_config_name}.nix"

  local nix_build_args=()
  build_nix_search_path_args_from_system_cfg_dir "nix_build_args" "$system_config_dir_inner_0"

  nix_build_args+=("--argstr" "device_identifier" "$device_id")
  # TODO: No longer needed. Deprecated. Remove at some point.
  nix_build_args+=("--argstr" "device_system_config_src_dir" "$system_config_src_dir_inner_1")
  nix_build_args+=("--argstr" "device_system_config_dir" "$system_config_dir_inner_0")

  build_nixos_config_dir "$out_var_name" "$update_config_filename" "${nix_build_args[@]}"
  eval "$out_system_config_dir_var_name='$system_config_dir_inner_0'"
  eval "$out_system_config_src_dir_var_name='$system_config_src_dir_inner_1'"
  echo "_build_system_config_dir_update end"
}


_install_system_closure() {
  echo "_install_system_closure - begin"
  local system_closure="$1"
  local action="$2"
  # Those are the currently support actions:
  # local action="build"
  # local action="boot"
  # local action="switch"

  case "$action" in
    switch|boot|build)
      ;;
    *)
      1>&2 echo "ERROR: _install_system_closure: Unsupported action '$action'."
      ;;
  esac

  local profile=/nix/var/nix/profiles/system
  local profile_name="system"

  echo "system_closure='$system_closure'"
  echo "action='$action'"

  if [ "$action" = "switch" ] || [ "$action" = "boot" ]; then
    if [ "$profile_name" != system ]; then
      profile="/nix/var/nix/profiles/system-profiles/$system_closure"
      mkdir -p -m 0755 "$(dirname "$profile")"
    fi
    nix-env -p "$profile" --set "$system_closure"
  fi

  if [ "$action" = "switch" ] || [ "$action" = "boot" ] \
      || [ "$action" = "test" ] || [ "$action" = "dry-activate" ]; then
    "$system_closure/bin/switch-to-configuration" "$action" || \
      { echo "warning: error(s) occurred while switching to the new configuration" >&2; exit 1; }
  fi

  echo "_install_system_closure - end"
}


_build_and_install_system_update() {
  echo "_build_and_install_system_update begin"
  local system_cfg_up_dir="$1"
  local default_action
  default_action="$(_get_default_install_action)"
  local action="${2:-"$default_action"}"

  echo "system_cfg_up_dir='$system_cfg_up_dir'"

  local system_closure
  if [[ -x "$system_cfg_up_dir/bin/switch-to-configuration" ]]; then

    # The update is a plain nixos system closure. Use it as is.
    echo "'system_cfg_up_dir' is a plain nixos system closure."
    system_closure="$system_cfg_up_dir"
    echo "system_closure='$system_closure'"
    _install_system_closure "$system_closure" "$action"

  elif [[ -f "$system_cfg_up_dir/etc/nixos-device-system-config/configuration.nix" ]] \
      && [[ -d "$system_cfg_up_dir/etc/nixos-device-system-config/nix-search-path" ]] \
      && [[ -x "$system_cfg_up_dir/bin/current-system-config-update-build-and-install" ]]; then

    # This is a prepackaged system config update with its own install script which
    # known how to build the embedded system config and install it. Simply run the
    # build and install script.
    echo "'system_cfg_up_dir' is a sytem config update with its own build and install script."
    "$system_cfg_up_dir/bin/current-system-config-update-build-and-install" "$action"

  elif [[ -f "$system_cfg_up_dir/etc/nixos-device-system-config/configuration.nix" ]] \
      && [[ -d "$system_cfg_up_dir/etc/nixos-device-system-config/nix-search-path" ]] \
      && ! [[ -d "$system_cfg_up_dir/bin" ]]; then

    echo "'system_cfg_up_dir' is a passive system configuration directory."
    build_device_config_system_closure "system_closure" "$system_cfg_up_dir" || return 1
    echo "system_closure='$system_closure'"
    _install_system_closure "$system_closure" "$action"
  else
    1>&2 echo "ERROR: Unrecognised system update format: '$system_cfg_up_dir'."
    exit 1
  fi

  echo "_build_and_install_system_update end"
}


_fetch_build_and_install_system_closure() {
  echo "_fetch_build_and_install_system_closure begin"

  local default_action
  default_action="$(_get_default_install_action)"
  local action="${1:-"$default_action"}"

  local system_cfg_up_dir
  local system_config_dir_inner_1
  local system_config_src_dir_inner_2
  _build_system_config_dir_update "system_cfg_up_dir" "system_config_dir_inner_1" "system_config_src_dir_inner_2"
  echo "system_config_src_dir='$system_config_src_dir_inner_2'"
  echo "system_config_dir='$system_config_dir_inner_1'"
  echo "system_cfg_up_dir='$system_cfg_up_dir'"
  _build_and_install_system_update "$system_cfg_up_dir" "$action"

  echo "_fetch_build_and_install_system_closure end"
}


update_current_system_fetch_only() {
  local system_config_src_dir
  local system_config_src_info_json
  _fetch_current_system_config_repo \
    "system_config_src_dir" "system_config_src_info_json"

  echo "system_config_src_dir='$system_config_src_dir'"
  echo "system_config_src_info_json='$system_config_src_info_json'"

  local rev
  rev="$(echo "$system_config_src_info_json" | jq -j .rev)"
  echo "rev='$rev'"
  local sha256
  sha256="$(echo "$system_config_src_info_json" | jq -j .sha256)"
  echo "sha256='$sha256'"
}


update_current_system_fetch_and_build_system_config_only() {
  local system_config_dir
  local system_config_src_dir
  _build_system_config_dir "system_config_dir" "system_config_src_dir"
  echo "system_config_src_dir='$system_config_src_dir'"
  echo "system_config_dir='$system_config_dir'"
}


update_current_system_fetch_and_build_system_config_update_only() {
  local system_cfg_up_dir
  local system_config_dir
  local system_config_src_dir
  _build_system_config_dir_update "system_cfg_up_dir" "system_config_dir" "system_config_src_dir"
  echo "system_config_src_dir='$system_config_src_dir'"
  echo "system_config_dir='$system_config_dir'"
  echo "system_cfg_up_dir='$system_cfg_up_dir'"
}


update_current_system_fetch_and_build_system_closure_only() {
  # Only build, no install.
  local action="build"
  _fetch_build_and_install_system_closure "$action"
}


build_and_install_system_update() {
  _build_and_install_system_update "$@"
}


_update_current_system_impl() {
  local default_action
  default_action="$(_get_default_install_action)"
  local action="${1:-"$default_action"}"
  _fetch_build_and_install_system_closure "$action"
}


update_current_system() {
  local default_action="boot"
  _update_current_system_impl "$default_action"
}


update_current_system_now() {
  local action="switch"
  _update_current_system_impl "$action"
}


update_current_system_next_boot() {
  local action="boot"
  _update_current_system_impl "$action"
}
