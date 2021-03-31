#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nsf-factory-common-install-get-sh-lib-dir)"
# Source all dependencies:
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/mount.sh
. "$common_factory_install_sh_lib_dir/mount.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/ssh.sh
. "$common_factory_install_sh_lib_dir/ssh.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/gpg.sh
. "$common_factory_install_sh_lib_dir/gpg.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/prompt.sh
. "$common_factory_install_sh_lib_dir/prompt.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_info_store.sh
. "$common_factory_install_sh_lib_dir/app_factory_info_store.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_gopass.sh
. "$common_factory_install_sh_lib_dir/app_factory_gopass.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/app_factory_gpg.sh
. "$common_factory_install_sh_lib_dir/app_factory_gpg.sh"





_DEFAULT_FACTORY_SECURE_RAMFS_MOUNT_DIR="$TEMP/nixos_factory_secure_ramfs"

_DEFAULT_FACTORY_SECURE_TMPFS_DIR="$TEMP/nixos_factory_secure_tmpfs"


is_user_wheel() {
  groups | tr ' ' '\n' | grep -q wheel && echo ok
}


get_factory_secure_ramfs_mount_dir() {
  echo "$_DEFAULT_FACTORY_SECURE_RAMFS_MOUNT_DIR"
}


get_factory_secure_tmpfs_dir() {
  echo "$_DEFAULT_FACTORY_SECURE_TMPFS_DIR"
}


mount_factory_secure_dir_impl() {
  mount_secure_ramfs "$(get_factory_secure_ramfs_mount_dir)"
}


umount_factory_secure_dir_impl() {
  umount_secure_ramfs "$(get_factory_secure_ramfs_mount_dir)"
}


get_factory_secure_dir_impl() {
  ramfs_dir="$(get_factory_secure_ramfs_mount_dir)"
  if mountpoint -q "$ramfs_dir"; then
    echo "$ramfs_dir"
    return 0
  fi

  tmpfs_dir="$(get_factory_secure_tmpfs_dir)"

  1>&2 echo "WARNING: Secure ramfs mount not mounted at '$ramfs_dir'."
  1>&2 echo " -> Fallbacking to less secure tmpfs at '$tmpfs_dir'."
  echo "$tmpfs_dir"
}


list_factory_secure_dir_content() {
  secure_dir="$(get_factory_secure_dir_impl)"
  if ! test -e "$secure_dir"; then
    return 1
  fi
  out_list="$(find "$secure_dir" -mindepth 1 -maxdepth 1)"
  if test "" == "$out_list"; then
    # Empty
    return 1
  fi

  echo "$out_list"
}


wipe_factory_secure_dir_content() {
  printf -- "Wipping factory secure dir content\n"
  printf -- "==================================\n\n"

  local to_be_wiped
  if ! to_be_wiped="$(list_factory_secure_dir_content)"; then
    echo "Nothing to wipe."
    return 0
  fi

  echo "The following files / directories will be wipped:"
  echo "$to_be_wiped"
  printf -- "\n"
  prompt_for_user_approval ""

  echo "$to_be_wiped" | xargs -r rm -r --
}


rm_factory_ssh_identity_impl() {
  prompt_before_rm_ssh_identity "" && \
  rm_current_user_ssh_identity ""
}


create_factory_ssh_identity_cli() {
  printf -- "\n"
  printf -- "Creating factory ssh identity\n"
  printf -- "=============================\n\n"

  local user_full_name
  read_or_prompt_for_factory_info__user_full_name "user_full_name"
  local user_email
  read_or_prompt_for_factory_info__user_email "user_email"

  SSH_TOOLS_KEYGEN_COMMENT="${user_full_name} <${user_email}>" \
    create_current_user_ssh_identity ""

  printf -- "\n"
  printf -- "Copying factory ssh public key to clipboard\n"
  printf -- "-------------------------------------------\n\n"

  copy_current_user_ssh_public_key_to_clipboard ""
  printf -- "\n"
  echo "Note that you will be able to retrieve this information "
  echo "at any time using the 'copy_factory_ssh_identity_to_clipboard' tool."
}


copy_factory_ssh_identity_to_clipboard_cli() {
  printf -- "\n"
  printf -- "Copying factory ssh public key to clipboard\n"
  printf -- "===========================================\n\n"

  copy_current_user_ssh_public_key_to_clipboard ""
}


rm_factory_gpg_identity_cli() {
  printf -- "\n"
  printf -- "Removing user gpg identity(ies)\n"
  printf -- "===============================\n\n"

  local gpg_id
  read_or_prompt_for_factory_info__user_gpg_default_id "gpg_id"
  local gpg_passphrase
  prompt_for_passphrase_no_repeat_loop "gpg_passphrase"

  GPG_TOOLS_PROMPT_BEFORE_IDENTITY_REMOVAL=1 \
    rm_current_user_gpg_identity "$gpg_id" "$gpg_passphrase"
}


create_factory_gpg_identity_cli() {
  printf -- "\n"
  printf -- "Creating factory gpg identity\n"
  printf -- "=============================\n\n"

  read_or_prompt_for_factory_info__user_full_name "user_full_name"
  read_or_prompt_for_factory_info__user_email "user_email"
  prompt_for_passphrase_loop "gpg_passphrase"

  local user_gpg_expire_date
  if test -z "${NSF_FACTORY_USER_GPG_EXPIRE_DATE+x}"; then
    read_or_prompt_for_factory_info__user_gpg_default_expire_date "user_gpg_expire_date"
  else
    user_gpg_expire_date="$NSF_FACTORY_USER_GPG_EXPIRE_DATE"
  fi

  local secure_dir
  secure_dir="$(get_factory_secure_dir_impl)"
  create_current_user_gpg_identity \
    "$user_email" \
    "$user_full_name" \
    "$gpg_passphrase" \
    "$user_gpg_expire_date" \
    "$secure_dir"

  printf -- "\n"
  printf -- "Listing master key files so that user copy these to a usb stick\n"
  printf -- "---------------------------------------------------------------\n\n"

  local master_key_dir
  master_key_dir="$(get_default_gpg_master_key_target_dir "$secure_dir")"

  local master_key_files
  master_key_files="$(list_gpg_master_key_files "$user_email" "$secure_dir")"

  echo "The following master key files have been kept available under '$master_key_dir':"
  echo "$master_key_files"
  printf -- "\n"

  echo "You should **copy those to an external / offline usb stick** and store it in a safe place."
  echo "You can use the 'factory-gpg-get-master-key-dir' tool to retrive the master key directory."
  printf -- "\n"
  echo "Once done, please **wipe those keys** using the 'factory-secrets-secure-dir-wipe-content' tool."


  local gpg_ids
  gpg_ids="$(list_gpg_secret_key_ids "" "$user_email" "$gpg_passphrase")" || return 1
  if ! test "1" -eq "$(echo "$gpg_ids" | wc -l)"; then
    1>&2 echo "ERROR: More than a single secret key or no key found for email '$user_email': '$gpg_ids'."
    return 1
  fi

  local gpg_id
  gpg_id="$(echo "$gpg_ids" | head -n 1)"

  printf -- "\n"
  printf -- "Copying factory gpg public key to clipboard\n"
  printf -- "-------------------------------------------\n\n"
  copy_current_user_gpg_public_key_to_clipboard "$gpg_id"

  printf -- "\n"
  echo "Note that you will be able to retrieve this information "
  echo "at any time using the 'copy_factory_gpg_identity_to_clipboard' tool."
}


copy_factory_gpg_identity_to_clipboard_cli() {
  printf -- "\n"
  printf -- "Copying factory gpg public key to clipboard\n"
  printf -- "===========================================\n\n"

  local gpg_id
  read_or_prompt_for_factory_user_gpg_default_id "gpg_id"
  echo "gpg_id='$gpg_id'"
  copy_current_user_gpg_public_key_to_clipboard "$gpg_id"
}


get_factory_gpg_master_key_dir_cli() {
  local secure_dir
  secure_dir="$(get_factory_secure_dir_impl)"

  local master_key_dir
  master_key_dir="$(get_default_gpg_master_key_target_dir "$secure_dir")"

  user_email="$(get_factory_info__user_email)"

  ensure_contains_gpg_master_key_files "$user_email" "$secure_dir"

  echo "$master_key_dir"
}


rm_factory_secret_vaults_user_config() {
  rm_factory_gopass_main_store_and_config
}


init_factory_secret_vaults_user_config() {
  print_title_lvl1 "Initializing factory gopass main store and config"
  init_factory_gopass_main_store_and_config
}


mount_factory_secret_vaults() {
  print_title_lvl4 "mount_factory_secret_vaults"
  mount_factory_gopass_secrets_stores
}


umount_factory_secret_vaults() {
  print_title_lvl4 "umount_factory_secret_vaults"
  umount_factory_gopass_secrets_stores
}


mount_factory_secret_vaults_cli() {
  print_title_lvl1 "Mounting factory secret vaults"

  local shallow="false"
  if printf "%s\n" "$@" | grep -q '\-\-shallow'; then
    shallow=true
  fi

  print_title_lvl2 "Mounting factory secret vaults themselves"
  mount_factory_secret_vaults

  if ! $shallow; then
    print_title_lvl2 "Mounting per device substores"
    mount_all_gopass_factory_device_substores
  fi
}


umount_factory_secret_vaults_cli() {
  print_title_lvl1 "Unmounting factory secret vaults"

  local shallow="false"
  if printf "%s\n" "$@" | grep -q '\-\-shallow'; then
    shallow=true
  fi

  if ! $shallow; then
    print_title_lvl2 "Unmounting per device substores"
    umount_all_gopass_factory_device_substores
  fi

  print_title_lvl2 "Unmounting factory secret vaults themselves"
  umount_factory_secret_vaults
}


list_factory_secrets_gpg_public_keys_cli() {
  list_factory_gpg_public_key_ids_w_email "$@"
}


list_factory_secrets_gpg_secret_keys_cli() {
  list_factory_gpg_secret_key_ids_w_email "$@"
}


list_factory_secrets_vaults_gopass_recipients_cli() {
  list_factory_gopass_vaults_recipients
}

import_factory_secrets_gopass_vaults_gpg_keys_cli() {
  import_all_authorized_peers_public_key_files_from_gopass_vaults
}
