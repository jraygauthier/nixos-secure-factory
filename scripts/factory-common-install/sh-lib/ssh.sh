#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/prompt.sh
. "$common_factory_install_sh_lib_dir/prompt.sh"

# From dependency libs.
common_install_sh_lib_dir="$(pkg-nixos-sf-common-install-get-sh-lib-dir)"
# shellcheck source=ssh.sh
. "$common_install_sh_lib_dir/ssh.sh"





create_ssh_identity() {
  local ssh_homedir="$1"
  local id_name="${2:-id}"
  local id_key_type="${3:-rsa}"
  local id_suffix="${4:-}"
  local id_rsa_key_bits="4096"
  local id_path="$ssh_homedir/${id_name}_${id_key_type}${id_suffix}"
  local id_path_pub="${id_path}.pub"

  printf -- "\n"
  printf -- "### Creating ssh identity ###\n\n"

  ensure_no_ssh_identity_present "$@"

  local default_comment
  default_comment="$(logname)@$(hostname)"
  local comment="${SSH_TOOLS_KEYGEN_COMMENT:-"$default_comment"}"

  local pw_args=()
  if [ -z "${SSH_TOOLS_KEYGEN_PW+x}" ]; then
    true
  else
    echo "Specific password provided through 'SSH_TOOLS_KEYGEN_PW' env var."
    pw_args=("-N" "${SSH_TOOLS_KEYGEN_PW:-}")
  fi

  echo "Creating ssh dir at '$ssh_homedir'."
  mkdir -m 0700 -p "$ssh_homedir"

  echo "Generating the public and private keys:"
  for id_f in ${id_path_pub} ${id_path}; do
    echo " -> '$id_f'"
  done
  if test "rsa" == "$id_key_type"; then
    # Increase rsa key lenght to something better.
    ssh-keygen "${pw_args[@]}" -t "$id_key_type" -b "$id_rsa_key_bits" -f "$id_path" -C "$comment"
  else
    ssh-keygen "${pw_args[@]}" -t "$id_key_type" -f "$id_path" -C "$comment"
  fi

  find "$ssh_homedir" | xargs -r stat -c '%a %n'
  printf -- "\n"
}


force_create_ssh_identity() {
  rm_ssh_identity "$@" || true
  create_ssh_identity "$@"
}


build_ssh_port_args_for_ssh_port() {
  local ssh_port="${1:-}"
  if [[ "${ssh_port:-}" == "" ]]; then
    echo "" # No args, use default port.
  else
    echo " -p $ssh_port"
  fi
}


build_ssh_port_args_for_ssh_port_a() {
  local -n _out_args_a="$1"
  local ssh_port="${2:-}"
  if [[ "${ssh_port:-}" == "" ]]; then
    _out_args_a=() # No args, use default port.
  else
    _out_args_a=( "-p" "$ssh_port" )
  fi
}


build_scp_port_args_for_ssh_port() {
  local ssh_port="${1:-}"
  if [[ "${ssh_port:-}" == "" ]]; then
    echo "" # No args, use default port.
  else
    # Note how scp use the big P instead of the small like ssh.
    echo " -P $ssh_port"
  fi
}


build_hostname_with_optional_colon_port_fragment() {
  local hostname="${1:-}"
  local port="${2:-}"
  if [[ "${port:-}" == "" ]]; then
    echo "${hostname}" # No args, use default port.
  else
    # Note how scp use the big P instead of the small like ssh.
    echo "${hostname}:${port}"
  fi
}


build_knownhost_id_from_hostname_and_opt_port() {
  local hostname="${1:-}"
  local port="${2:-}"
  if [[ "${port:-}" == "" ]]; then
    echo "${hostname}" # No args, use default port.
  else
    # Note how scp use the big P instead of the small like ssh.
    echo "[${hostname}]:${port}"
  fi
}


prompt_before_rm_ssh_identity() {
  local id_files
  if ! id_files="$(list_ssh_identity_files "$@")"; then
    return 0
  fi

  echo "Will remove the following file which is your current ssh identity:"
  for id_f in $id_files; do
    echo " -> '$id_f'"
  done

  prompt_for_user_approval
}


get_ssh_public_key_path() {
  local ssh_homedir="$1"
  local id_name="${2:-id}"
  local id_key_type="${3:-rsa}"
  local id_suffix="${4:-}"
  local id_path="$ssh_homedir/${id_name}_${id_key_type}${id_suffix}"
  local id_path_pub="${id_path}.pub"
  echo "$id_path_pub"
}


copy_ssh_public_key_to_clipboard() {
  local id_path_pub
  id_path_pub="$(get_ssh_public_key_path "$@")"
  DISPLAY="${DISPLAY:-":0"}" xclip -selection clipboard "$id_path_pub"
  echo "'$id_path_pub' has been placed in your clipboard. Paste it where you need."
  printf -- "\n"
}


create_current_user_ssh_identity() {
  create_ssh_identity "$HOME/.ssh" "$@"
}


rm_current_user_ssh_identity() {
  rm_ssh_identity "$HOME/.ssh" "$@"
}


force_create_current_user_ssh_identity() {
  force_create_ssh_identity "$HOME/.ssh" "$@"
}



get_current_user_ssh_public_key_path() {
  get_ssh_public_key_path "$HOME/.ssh" "$@"
}


copy_current_user_ssh_public_key_to_clipboard() {
  copy_ssh_public_key_to_clipboard "$HOME/.ssh" "$@"
}
