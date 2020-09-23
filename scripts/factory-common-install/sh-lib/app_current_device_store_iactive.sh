#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/prompt.sh
. "$common_factory_install_sh_lib_dir/prompt.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_current_device_store.sh
. "$common_factory_install_sh_lib_dir/app_current_device_store.sh"


read_or_prompt_for_current_device__hostname() {
  local out_varname="$1"
  local out="null"
  if is_current_device_specified; then
    out="$(get_resolved_current_device_hostname)" || return 1
  fi

  if [[ "$out" == "null" ]] || [[ "$out" == "" ]]; then
    prompt_for_mandatory_parameter "$out_varname" "hostname"
  else
    eval "${out_varname}=${out}"
  fi
}


read_or_prompt_for_current_device__ssh_port() {
  local out_varname="$1"
  local out=""
  if is_current_device_specified; then
    out="$(get_resolved_current_device_ssh_port)" || return 1
  fi

  # TODO: auto -> retrieve from backend (e.g.: vbox backend).
  if [[ "$out" == "auto" ]]; then
    out="2222"
  fi

  if [[ "$out" == "null" ]] || [[ "$out" == "" ]]; then
    prompt_for_optional_parameter "$out_varname" "ssh_port"
  else
    eval "${out_varname}=${out}"
  fi
}

