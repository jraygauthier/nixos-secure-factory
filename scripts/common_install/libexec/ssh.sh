#!/usr/bin/env bash
# common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"



get_host_key_name() {
  echo "ssh_host"
}


get_host_key_suffix() {
  echo "_key"
}


get_host_key_basename_from_key_type() {
  local key_type=$1
  echo "$(get_host_key_name)_${key_type}$(get_host_key_suffix)"
}


list_ssh_identity_files() {
  local ssh_homedir="${1:-"$HOME/.ssh"}"
  local id_name="${2:-id}"
  local id_key_type="${3:-rsa}"
  local id_suffix="${4:-}"
  local id_path="$ssh_homedir/${id_name}_${id_key_type}${id_suffix}"
  local id_path_pub="${id_path}.pub"

  if ! test -f "$id_path" && ! test -f "$id_path_pub"; then
    return 1
  fi

  if test -f "$id_path"; then
    echo "$id_path"
  fi

  if test -f "$id_path_pub"; then
    echo "$id_path_pub"
  fi
}


is_ssh_identity_present() {
  list_ssh_identity_files "$@"
}


ensure_no_ssh_identity_present() {
  local ssh_homedir="$1"
  local id_name="${2:-id}"
  local id_key_type="${3:-rsa}"
  local id_suffix="${4:-}"
  local id_path="$ssh_homedir/${id_name}_${id_key_type}${id_suffix}"
  local id_path_pub="${id_path}.pub"

  if is_ssh_identity_present "$@"; then
    2>&1 echo "ERROR: User already has ssh identity named '$id_name'."
    2>&1 echo "  Please rm the following files manually (\`rm_factory_ssh_identity\`) and re-run this:"
    for id_f in ${id_path_pub} ${id_path}; do
      2>&1 echo "   -> '$id_f'"
    done

    exit 1
  fi
}


rm_ssh_identity() {
  local ssh_homedir="$1"
  local id_name="${2:-id}"
  local id_key_type="${3:-rsa}"
  local id_suffix="${4:-}"
  local id_path="$ssh_homedir/${id_name}_${id_key_type}${id_suffix}"
  local id_path_pub="${id_path}.pub"

  printf -- "\n"
  printf -- "Removing user ssh identity\n"
  printf -- "==========================\n\n"

  if ! is_ssh_identity_present "$@"; then
    2>&1 echo "WARNING: No identity found at '${id_path_pub}'. Nothing to do."
    return 1
  fi

  for id_f in ${id_path_pub} ${id_path}; do
    echo "Removing '$id_f'"
    rm -f "$id_f"
  done
  printf -- "\n"
}
