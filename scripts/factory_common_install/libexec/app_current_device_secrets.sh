#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
# Source both dependencies.
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/mount.sh"
. "$common_factory_install_libexec_dir/ssh.sh"
. "$common_factory_install_libexec_dir/gpg.sh"
. "$common_factory_install_libexec_dir/gopass.sh"
. "$common_factory_install_libexec_dir/prompt.sh"
. "$common_factory_install_libexec_dir/app_current_device_store.sh"
. "$common_factory_install_libexec_dir/app_current_device_gopass_vault.sh"
. "$common_factory_install_libexec_dir/app_current_device_ssh.sh"
. "$common_factory_install_libexec_dir/app_factory_secrets.sh"
. "$common_factory_install_libexec_dir/app_current_device_liveenv.sh"


# From deps libs.
common_install_libexec_dir="$(pkg-nixos-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/device_secrets.sh"


mount_device_secure_dir_impl() {
  run_cmd_as_device_root "liveenv-mount-device-secure-dir"
}


umount_device_secure_dir_impl() {
  run_cmd_as_device_root "liveenv-umount-device-secure-dir"
}


mount_device_secret_vaults() {
  print_title_lvl4 "umount_device_secret_vaults"
  mount_factory_secret_vaults
  mount_gopass_device
}


umount_device_secret_vaults() {
  print_title_lvl4 "umount_device_secret_vaults"
  mount_factory_secret_vaults
  deauthorize_gopass_device_from_device_private_substore
  umount_gopass_device
}


rm_no_prompt_device_secret_vaults() {
  print_title_lvl4 "rm_no_prompt_device_secret_vaults"
  mount_factory_secret_vaults
  rm_no_prompt_gopass_device
  rm_no_prompt_gopass_factory_only_device
}

wipe_device_secure_dir_content() {
  wipe_factory_secure_dir_content
}

get_device_secrets_on_factory_secure_dir() {
  echo "$(get_factory_secure_dir_impl)/device"
}


get_device_created_secrets_secure_dir() {
  echo "$(get_device_secrets_on_factory_secure_dir)/created"
}


get_device_stored_secrets_secure_dir() {
  echo "$(get_device_secrets_on_factory_secure_dir)/stored"
}


get_device_factory_only_stored_secrets_secure_dir() {
  echo "$(get_device_secrets_on_factory_secure_dir)/factory_only_stored"
}


_is_text_file() {
  local in_file="$1"
  local mime_enc
  mime_enc="$(file -L --mime-encoding "$in_file" | awk -F':' '{ print $2 }')"

  if echo "$mime_enc" | grep -q "binary"; then
    false
  elif echo "$mime_enc" | grep -q "ascii"; then
    true
  elif echo "$mime_enc" | grep -q "utf-8"; then
    true
  else
    1>&2 echo "ERROR: Unknown / unsupported \`file --mime-encoding\` value: '$mime_enc'."
  fi
}


_store_device_secret_files() {
  local rel_expected_secrets_files="$1"
  local created_secrets_root
  created_secrets_root="$(get_device_created_secrets_secure_dir)"
  for rf in $rel_expected_secrets_files; do
    local in_f="${created_secrets_root}/${rf}"
    store_gopass_device_bin_file_secret "$rf" "$in_f" || exit 1
    # if _is_text_file "$in_f"; then
    #   store_gopass_device_text_file_secret "$rf" "$in_f" || exit 1
    # else
    #   store_gopass_device_bin_file_secret "$rf" "$in_f" || exit 1
    # fi
  done
}


_load_device_secret_files() {
  local rel_expected_secrets_files="$1"
  local rel_root_dir_of_given_secrets="$2"

  local stored_secrets_root
  stored_secrets_root="$(get_device_stored_secrets_secure_dir)"

  for rf in $rel_expected_secrets_files; do
    local out_f="${stored_secrets_root}/${rf}"
    load_gopass_device_bin_file_secret "$rf" "$out_f" || exit 1
    # if exists_gopass_device_text_secret "$rf"; then
    #   load_gopass_device_text_file_secret "$rf" "$out_f" || exit 1
    # else
    #   load_gopass_device_bin_file_secret "$rf" "$out_f" || exit 1
    # fi
  done

  find "$stored_secrets_root/$rel_root_dir_of_given_secrets" -exec stat -c '%a %n' {} +
}


_check_device_secret_files() {
  local rel_expected_secrets_files="$1"
  local rel_root_dir_of_given_secrets="$2"

  local created_secrets_root
  created_secrets_root="$(get_device_created_secrets_secure_dir)"
  local stored_secrets_root
  stored_secrets_root="$(get_device_stored_secrets_secure_dir)"

  for rf in $rel_expected_secrets_files; do
    local created_f="${created_secrets_root}/${rf}"
    local loaded_f="${stored_secrets_root}/${rf}"
    if ! echo_eval "diff --color=always -u '$created_f' '$loaded_f'"; then
      1>&2 echo "ERROR: Mismatching created / loaded secret."
      1>&2 echo " -> Created at: '$created_f'"
      1>&2 echo " -> Loaded at: '$loaded_f'"
      exit 1
    fi
  done

  find "$stored_secrets_root/$rel_root_dir_of_given_secrets" -exec stat -c '%a %n' {} +
}


_store_device_factory_only_secret_files() {
  local rel_expected_secrets_files="$1"
  local created_secrets_root
  created_secrets_root="$(get_device_created_secrets_secure_dir)"
  for rf in $rel_expected_secrets_files; do
    in_f="${created_secrets_root}/${rf}"
    store_gopass_factory_only_device_bin_file_secret "$rf" "$in_f" || exit 1
    # if _is_text_file "$in_f"; then
    #   store_gopass_factory_only_device_text_file_secret "$rf" "$in_f" || exit 1
    # else
    #   store_gopass_factory_only_device_bin_file_secret "$rf" "$in_f" || exit 1
    # fi
  done
}


_load_device_factory_only_secret_files() {
  local rel_expected_secrets_files="$1"
  local rel_root_dir_of_given_secrets="$2"

  local created_secrets_root
  created_secrets_root="$(get_device_created_secrets_secure_dir)"
  local stored_secrets_root
  stored_secrets_root="$(get_device_factory_only_stored_secrets_secure_dir)"

  for rf in $rel_expected_secrets_files; do
    out_f="${stored_secrets_root}/${rf}"
    load_gopass_factory_only_device_bin_file_secret "$rf" "$out_f" || exit 1
    # if exists_gopass_factory_only_device_text_secret "$rf"; then
    #   load_gopass_factory_only_device_text_file_secret "$rf" "$out_f" || exit 1
    # else
    #   load_gopass_factory_only_device_bin_file_secret "$rf" "$out_f" || exit 1
    # fi
  done

  find "$stored_secrets_root/$rel_root_dir_of_given_secrets" -exec stat -c '%a %n' {} +
}


_check_device_factory_only_secret_files() {
  local rel_expected_secrets_files="$1"
  local rel_root_dir_of_given_secrets="$2"

  local created_secrets_root
  created_secrets_root="$(get_device_created_secrets_secure_dir)"
  local stored_secrets_root
  stored_secrets_root="$(get_device_factory_only_stored_secrets_secure_dir)"

  for rf in $rel_expected_secrets_files; do
    local created_f="${created_secrets_root}/${rf}"
    local loaded_f="${stored_secrets_root}/${rf}"
    if ! echo_eval "diff --color=always -u '$created_f' '$loaded_f'"; then
      1>&2 echo "ERROR: Mismatching created / loaded secret."
      1>&2 echo " -> Created at: '$created_f'"
      1>&2 echo " -> Loaded at: '$loaded_f'"
      exit 1
    fi
  done

  find "$stored_secrets_root/$rel_root_dir_of_given_secrets" -exec stat -c '%a %n' {} +
}


_get_device_factory_sent_secret_dir() {
  if ! is_device_run_from_nixos_liveenv; then
    # Target device is nixos so we can assume the run keys dir
    # is available.
    get_installed_device_factory_sent_secret_dir
    return 0
  fi

  local secret_dir
  if ! secret_dir="$(run_cmd_as_device_root 'os-secrets-get-secret-dir')"; then
    1>&2 echo "ERROR: _get_device_factory_sent_secret_dir: There was an error retriver the device's secret directory."
    exit 1
  fi
  echo "$secret_dir"
}


_deploy_device_secret_files() {
  local rel_expected_secrets_files="$1"
  local rel_root_dir_of_given_secrets="$2"

  local stored_secrets_root
  stored_secrets_root="$(get_device_stored_secrets_secure_dir)"
  remote_secrets_root="$(_get_device_factory_sent_secret_dir)" || exit 1

  for rf in $rel_expected_secrets_files; do
    local local_f="${stored_secrets_root}/${rf}"
    local remote_f="${remote_secrets_root}/${rf}"
    # Should prevent us from being kicked out because we're
    # opening too many ssh sessions too fast.
    sleep 0.3
    deploy_file_to_device "$local_f" "$remote_f" || exit 1
  done

  run_cmd_as_device_root "find '$remote_secrets_root/$rel_root_dir_of_given_secrets' | xargs -r stat -c '%a %n'"
}


create_device_root_user_ssh_identity() {
  print_title_lvl3 "Creating device root user ssh identity"

  local device_email
  device_email="$(get_required_current_device_email)" || exit 1

  local ssh_homedir
  ssh_homedir="$(get_device_created_secrets_secure_dir)/$(get_rel_root_user_ssh_homedir)"
  rm -rf "$ssh_homedir"

  for kt in $(list_expected_device_root_user_ssh_key_types); do
    SSH_TOOLS_KEYGEN_COMMENT="root user <${device_email}>" \
    SSH_TOOLS_KEYGEN_PW="" \
      create_ssh_identity "$ssh_homedir" \
        "" "$kt" ""
  done
}


store_device_root_user_ssh_identity() {
  print_title_lvl3 "Storing device root user ssh identity"
  _store_device_secret_files "$(list_rel_expected_root_user_ssh_key_files)"
}


load_device_root_user_ssh_identity() {
  print_title_lvl3 "Loading device root user ssh identity"

  _load_device_secret_files \
    "$(list_rel_expected_root_user_ssh_key_files)" \
    "$(get_rel_root_user_ssh_homedir)"
}


check_device_root_user_ssh_identity() {
  print_title_lvl3 "Checking device root user ssh identity"

  _check_device_secret_files \
    "$(list_rel_expected_root_user_ssh_key_files)" \
    "$(get_rel_root_user_ssh_homedir)"
}


deploy_device_root_user_ssh_identity() {
  print_title_lvl3 "Deploying device root user ssh identity"

  local remote_secrets_root
  remote_secrets_root="$(_get_device_factory_sent_secret_dir)/$(get_rel_root_user_ssh_homedir)"
  run_cmd_as_device_root "mkdir -m 700 -p \"$remote_secrets_root\""

  _deploy_device_secret_files \
    "$(list_rel_expected_root_user_ssh_key_files)" \
    "$(get_rel_root_user_ssh_homedir)"
}


create_device_host_ssh_identity() {
  print_title_lvl3 "Creating device host ssh identity"

  local device_email
  device_email="$(get_required_current_device_email)" || exit 1

  local ssh_homedir
  ssh_homedir="$(get_device_created_secrets_secure_dir)/$(get_rel_host_ssh_homedir)"
  rm -rf "$ssh_homedir"

  for kt in $(list_expected_device_host_ssh_key_types); do
    SSH_TOOLS_KEYGEN_COMMENT="host <${device_email}>" \
    SSH_TOOLS_KEYGEN_PW="" \
      create_ssh_identity "$ssh_homedir" \
        "$(get_host_key_name)" "$kt" "$(get_host_key_suffix)"
  done
}


store_device_host_ssh_identity() {
  print_title_lvl3 "Storing device host ssh identity"
  _store_device_secret_files "$(list_rel_expected_host_ssh_key_files)"
}


load_device_host_ssh_identity() {
  print_title_lvl3 "Loading device host ssh identity"

  _load_device_secret_files \
    "$(list_rel_expected_host_ssh_key_files)" \
    "$(get_rel_host_ssh_homedir)"
}


check_device_host_ssh_identity() {
  print_title_lvl3 "Checking device host ssh identity"

  _check_device_secret_files \
    "$(list_rel_expected_host_ssh_key_files)" \
    "$(get_rel_host_ssh_homedir)"
}


deploy_device_host_ssh_identity() {
  print_title_lvl3 "Deploying device host ssh identity"

  local remote_secrets_root
  remote_secrets_root="$(_get_device_factory_sent_secret_dir)/$(get_rel_host_ssh_homedir)"
  run_cmd_as_device_root "mkdir -m 700 -p \"$remote_secrets_root\""
  _deploy_device_secret_files \
    "$(list_rel_expected_host_ssh_key_files)" \
    "$(get_rel_host_ssh_homedir)"
}


create_device_root_user_gpg_identity() {
  print_title_lvl3 "Creating device root user gpg identity"

  local device_email
  device_email="$(get_required_current_device_email)" || exit 1

  local gpg_homedir
  gpg_homedir="$(get_device_created_secrets_secure_dir)/$(get_rel_root_user_gpg_homedir)"
  rm -rf "$gpg_homedir"

  local user_name="root"
  local passphrase=""

  local secure_dir="$(get_factory_secure_dir_impl)"
  local gpg_tmp_dir="$secure_dir/gpg_device_root_user"
  rm -rf "$gpg_tmp_dir"

  create_gpg_master_keypair_and_export_to_dir \
    "$gpg_homedir" \
    "$device_email" \
    "$user_name" \
    "$passphrase" \
    "$gpg_tmp_dir"
}


store_device_root_user_gpg_identity() {
  print_title_lvl3 "Storing device root user gpg identity\n"
  _store_device_secret_files "$(list_rel_expected_root_user_gpg_laptop_keypair_files)"
  _store_device_factory_only_secret_files "$(list_rel_expected_root_user_gpg_master_keypair_files)"

  # list_rel_expected_root_user_gpg_master_keypair_files
}


load_device_root_user_gpg_identity() {
  print_title_lvl3 "Loading device host ssh identity"

  _load_device_secret_files \
    "$(list_rel_expected_root_user_gpg_laptop_keypair_files)" \
    "$(get_rel_root_user_gpg_homedir)"

  _load_device_factory_only_secret_files \
    "$(list_rel_expected_root_user_gpg_master_keypair_files)" \
    "$(get_rel_root_user_gpg_homedir)"
}


check_device_root_user_gpg_identity() {
  print_title_lvl3 "Checking device root user gpg identity"

  _check_device_secret_files \
    "$(list_rel_expected_root_user_gpg_laptop_keypair_files)" \
    "$(get_rel_root_user_gpg_homedir)"

  _check_device_factory_only_secret_files \
    "$(list_rel_expected_root_user_gpg_master_keypair_files)" \
    "$(get_rel_root_user_gpg_homedir)"
}


deploy_device_root_user_gpg_identity() {
  print_title_lvl3 "Deploying device root user gpg identity"

  local remote_secrets_root
  remote_secrets_root="$(_get_device_factory_sent_secret_dir)/$(get_rel_root_user_gpg_homedir)"
  run_cmd_as_device_root "mkdir -m 700 -p \"$remote_secrets_root\""

  _deploy_device_secret_files \
    "$(list_rel_expected_root_user_gpg_laptop_keypair_files)" \
    "$(get_rel_root_user_gpg_homedir)"
}


ls_device_secrets_groups_by_id() {
  echo "host_ssh_identity"
  echo "root_user_ssh_identity"
  echo "root_user_gpg_identity"
  # User passwords
}


ls_matching_device_secrets_groups_by_id() {
  local search_str="${1:-}"
  if [[ -n "$search_str" ]]; then
    ls_device_secrets_groups_by_id | grep "$search_str"
  else
    # Print all secrets groups when no search str provided.
    ls_device_secrets_groups_by_id
  fi
}


ls_device_secrets_ops_by_id() {
  echo "ls"
  # echo "rm_no_prompt"
  echo "create"
  echo "load"
  echo "check"
  echo "deploy"
}



_run_device_secrets_op_on_matchin_sgroups() {
  local op_id="$1"
  local search_str="${2:-}"

  for sg in $(ls_matching_device_secrets_groups_by_id "$search_str"); do
    ${op_id}_device_${sg} || exit 1
  done
}


ls_device_secrets() {
  _run_device_secrets_op_on_matchin_sgroups "ls" "$@"
}


rm_no_prompt_device_secrets_prim() {
  print_title_lvl2 "Removing device secrets from the vault."
  # _run_device_secrets_op_on_matchin_sgroups "rm_no_prompt"
  rm_no_prompt_device_secret_vaults
}


create_device_secrets_prim() {
  print_title_lvl2 "Creating device secrets to secure directory."
  _run_device_secrets_op_on_matchin_sgroups "create" "$@"

  # TODO: user passwords + hashs.
}


store_device_secrets_prim() {
  print_title_lvl2 "Storing device secrets to the vault."
  mount_device_secret_vaults
  _run_device_secrets_op_on_matchin_sgroups "store" "$@"
}


load_device_secrets_prim() {
  print_title_lvl2 "Loading device secrets from the vault to secure directory."
  mount_device_secret_vaults
  _run_device_secrets_op_on_matchin_sgroups "load" "$@"

  # TODO: Check that all expected secrets are found.
}


check_device_secrets_prim() {
  print_title_lvl2 "Checkout device secrets loaded from the vault to secure directory against created secrets"
  mount_device_secret_vaults
  _run_device_secrets_op_on_matchin_sgroups "check" "$@"
}


grant_access_device_secrets_prim() {
  print_title_lvl2 "Granting device access to its private vault"
  mount_device_secret_vaults
  authorize_gopass_device_to_device_private_substore
}

deploy_device_secrets_prim() {
  print_title_lvl2 "Deploying device secrets from secure directory to the device"
  _run_device_secrets_op_on_matchin_sgroups "deploy" "$@"
}


install_device_secrets_prim() {
  print_title_lvl2 "Installing device secrets on the device."
  run_cmd_as_device_root "os-secrets-install-received"
}

create_device_secrets() {
  print_title_lvl1 "Creating current device secrets and storing those to the vault"
  create_device_secrets_prim "$@"
  store_device_secrets_prim "$@"
  # We explicitly reload the secrets in order acertain their presence.
  load_device_secrets_prim "$@"
  check_device_secrets_prim "$@"
  grant_access_device_secrets_prim
}


create_and_deploy_device_secrets() {
  print_title_lvl1 "Creating and deploying current device secrets storing them to the vault"
  create_device_secrets_prim "$@"
  store_device_secrets_prim "$@"
  load_device_secrets_prim "$@"
  check_device_secrets_prim "$@"
  grant_access_device_secrets_prim
  if is_device_run_from_nixos_liveenv; then
    mount_liveenv_nixos_partitions
  fi
  deploy_device_secrets_prim "$@"
  install_device_secrets_prim
  # wipe_device_secure_dir_content
}


rm_device_secrets() {
  print_title_lvl1 "Removing current device secrets from the vault"
  # TODO: Return early when nothing to remove.

  # TODO: Print all the secrets that will be deleted.
  prompt_for_user_approval
  rm_no_prompt_device_secrets_prim
  # wipe_device_secure_dir_content
}


deploy_device_secrets() {
  print_title_lvl1 "Deploying current device secrets to the device"
  load_device_secrets_prim "$@"
  if is_device_run_from_nixos_liveenv; then
    mount_liveenv_nixos_partitions
  fi
  deploy_device_secrets_prim "$@"
  install_device_secrets_prim
  # wipe_device_secure_dir_content
}


deploy_no_install_device_secrets() {
  print_title_lvl1 "Deploying current device secrets to the device without installing"
  load_device_secrets_prim "$@"
  if is_device_run_from_nixos_liveenv; then
    mount_liveenv_nixos_partitions
  fi
  deploy_device_secrets_prim "$@"
  # wipe_device_secure_dir_content
}


install_deployed_device_secrets() {
  print_title_lvl1 "Install already deployed device secrets"
  install_device_secrets_prim
}


copy_device_ssh_identity_to_clipboard() {
  print_title_lvl1 "Copying current device ssh identity (root public key) to your clipboard"
  local store_key
  store_key="$(get_rel_root_user_ssh_rsa_public_key)"

  local full_store_key
  full_store_key="$(get_gopass_device_full_store_key_for "$store_key")"

  cat_gopass_device_bin_secret "$store_key" "ssh_pub_key" | xclip -selection clipboard
  echo "Device public key at '$full_store_key' has been placed in your clipboard. Paste it where you need."
}
