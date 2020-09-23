#!/usr/bin/env bash
device_common_install_sh_lib_dir="$(pkg-nsf-device-common-install-get-sh-lib-dir)"
. "$device_common_install_sh_lib_dir/nixos.sh"

# Source all dependencies:
common_install_sh_lib_dir="$(pkg-nsf-common-install-get-sh-lib-dir)"
. "$common_install_sh_lib_dir/mount.sh"
. "$common_install_sh_lib_dir/device_secrets.sh"



mount_device_secure_dir_impl() {
  mount_secure_ramfs "$(get_device_secure_ramfs_mount_dir)"
}


umount_device_secure_dir_impl() {
  umount_secure_ramfs "$(get_device_secure_ramfs_mount_dir)"
}


ensure_expected_secret_install_root_dir_exists() {
  if is_run_from_nixos_live_cd; then
    ensure_nixos_partition_mounted
  fi
}


get_secret_install_root_dir() {
  if is_run_from_nixos_live_cd; then
    echo "/mnt"
  else
    echo ""
  fi
}


get_device_secure_dir_impl() {
  ramfs_dir="$(get_device_secure_ramfs_mount_dir)"
  if mountpoint -q "$ramfs_dir"; then
    echo "$ramfs_dir"
    return 0
  fi

  if is_run_keys_dir_available; then
    echo "$(get_device_run_keys_secure_ramfs_dir)"
    return 0
  fi


  tmpfs_dir="$(get_device_secure_tmpfs_dir)"

  1>&2 echo "WARNING: Secure ramfs mount not mounted at '$ramfs_dir'."
  1>&2 echo " -> Fallbacking to less secure tmpfs at '$tmpfs_dir'."
  echo "$tmpfs_dir"
}


list_device_secure_dir_content() {
  secure_dir="$(get_device_secure_dir_impl)"
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


wipe_device_secure_dir_content() {
  print_title_lvl4 "Wipping device secure dir content"

  local to_be_wiped
  if ! to_be_wiped="$(list_device_secure_dir_content)"; then
    echo "Nothing to wipe."
    return 0
  fi

  echo "The following files / directories will be wipped:"
  echo "$to_be_wiped"
  printf -- "\n"

  echo "$to_be_wiped" | xargs -r rm -r --
}


get_factory_sent_secret_dir() {
  local secure_dir_root
  secure_dir_root="$(get_device_secure_dir_impl)"
  echo "$secure_dir_root/$(get_device_factory_sent_secret_dir_basename)"
}


wipe_factory_sent_secret_dir() {
  print_title_lvl3 "Wiping factory sent secret dir."
  rm -r "$(get_factory_sent_secret_dir)"
}


get_expected_factory_sent_host_ssh_homedir() {
  local from_factory
  from_factory="$(get_factory_sent_secret_dir)"
  echo "$from_factory/$(get_rel_host_ssh_homedir)"
}


get_expected_factory_sent_root_user_ssh_homedir() {
  local from_factory
  from_factory="$(get_factory_sent_secret_dir)"
  echo "$from_factory/$(get_rel_root_user_ssh_homedir)"
}


get_expected_factory_sent_root_user_gpg_homedir() {
  local from_factory
  from_factory="$(get_factory_sent_secret_dir)"
  echo "$from_factory/$(get_rel_root_user_gpg_homedir)"
}


ensure_factory_sent_ssh_identity_is_complete() {
  print_title_lvl4 "Ensuring factory sent ssh identity is complete"

  local from_factory
  from_factory="$(get_factory_sent_secret_dir)"

  for f in $(list_rel_expected_host_ssh_key_files); do
    local full_f="$from_factory/$f"
    if ! test -f "$full_f"; then
      1>&2 echo "ERROR: Missing host ssh identity file: '$full_f'."
      exit 1
    fi
  done

  for f in $(list_rel_expected_root_user_ssh_key_files); do
    local full_f="$from_factory/$f"
    if ! test -f "$full_f"; then
      1>&2 echo "ERROR: Missing root user ssh identity file: '$full_f'."
      exit 1
    fi
  done

}

ensure_factory_sent_gpg_identity_is_complete() {
  print_title_lvl4 "Ensuring factory sent gpg identity is complete"

  local from_factory
  from_factory="$(get_factory_sent_secret_dir)"

  for f in $(list_rel_expected_root_user_gpg_laptop_keypair_files); do
    local full_f="$from_factory/$f"
    if ! test -f "$full_f"; then
      1>&2 echo "ERROR: Missing gpg identity file: '$full_f'."
      exit 1
    fi
  done
}


_install_root_host_ssh_identity() {
  local open_ssh_cfg_dir="$1"

  ensure_factory_sent_ssh_identity_is_complete

  exec >&2
  local rx_openssh_homedir
  rx_openssh_homedir="$(get_expected_factory_sent_host_ssh_homedir)"

  mkdir -p "$open_ssh_cfg_dir"
  # Make sure the directory has the proper access rights.
  chmod 0755 "$open_ssh_cfg_dir"

  for kt in $(list_expected_device_host_ssh_key_types); do
    local key_basename
    key_basename="$(get_host_key_basename_from_key_type "${kt}")"

    local out_private="$open_ssh_cfg_dir/$key_basename"
    cp -p "$rx_openssh_homedir/$key_basename" "$out_private" || exit 1
    chmod 600 "$out_private" || exit 1

    local out_public="$open_ssh_cfg_dir/${key_basename}.pub"
    cp -p "$rx_openssh_homedir/${key_basename}.pub" "$out_public" || exit 1
    chmod 644 "$out_public" || exit 1
  done

  find "$open_ssh_cfg_dir" -exec stat -c '%a %n' {} +
}


install_device_host_ssh_identity() {
  print_title_lvl3 "Installing device ssh host identity sent by factory"

  ensure_expected_secret_install_root_dir_exists

  local open_ssh_cfg_dir
  open_ssh_cfg_dir="$(get_secret_install_root_dir)/$(get_rel_host_ssh_homedir)"
  _install_root_host_ssh_identity "$open_ssh_cfg_dir"
}


_install_root_user_ssh_identity() {
  print_title_lvl3 "Installing device ssh root user identity sent by factory"

  local root_user_ssh_dir="$1"

  ensure_factory_sent_ssh_identity_is_complete

  exec >&2

  local rx_root_ssh_homedir
  rx_root_ssh_homedir="$(get_expected_factory_sent_root_user_ssh_homedir)"

  mkdir -p "$root_user_ssh_dir"
  # Make sure the directory has the proper access rights.
  chmod 0700 "$root_user_ssh_dir"

  for kt in $(list_expected_device_root_user_ssh_key_types); do
    local key_basename="id_${kt}"

    local out_private="$root_user_ssh_dir/$key_basename"
    cp -p "$rx_root_ssh_homedir/$key_basename" "$out_private" || exit 1
    chmod 600 "$out_private" || exit 1

    local out_public="$root_user_ssh_dir/${key_basename}.pub"
    cp -p "$rx_root_ssh_homedir/${key_basename}.pub" "$out_public" || exit 1
    chmod 644 "$out_public" || exit 1
  done

  find "$root_user_ssh_dir" -exec stat -c '%a %n' {} +
}


install_device_root_user_ssh_identity() {
  print_title_lvl3 "Installing device ssh root user identity sent by factory"

  ensure_expected_secret_install_root_dir_exists

  local root_user_ssh_dir
  root_user_ssh_dir="$(get_secret_install_root_dir)/$(get_rel_root_user_ssh_homedir)"

  _install_root_user_ssh_identity "$root_user_ssh_dir"
}


install_liveenv_root_user_ssh_identity() {
  print_title_lvl3 "Installing liveenv ssh root user identity sent by factory"

  local root_user_ssh_dir
  root_user_ssh_dir="/$(get_rel_root_user_ssh_homedir)"

  _install_root_user_ssh_identity "$root_user_ssh_dir"
}


_install_root_user_gpg_identity() {
  local root_gpg_dir="$1"

  ensure_factory_sent_gpg_identity_is_complete

  local rx_root_gpg_homedir
  rx_root_gpg_homedir="$(get_expected_factory_sent_root_user_gpg_homedir)"

  # TODO: Consider backup instead.
  wipe_gpg_home_dir "$root_gpg_dir"

  local rx_subkeys
  rx_subkeys="$rx_root_gpg_homedir/$(get_gpg_subkeys_basename)"
  local rx_otrust
  rx_otrust="$rx_root_gpg_homedir/$(get_gpg_otrust_basename)"

  local passphrase=""
  import_gpg_subkeys "$root_gpg_dir" "$rx_subkeys" "$rx_otrust" "$passphrase"
}


install_device_root_user_gpg_identity() {
  print_title_lvl3 "Installing device gpg root user identity sent by factory"

  ensure_expected_secret_install_root_dir_exists

  local root_gpg_dir
  root_gpg_dir="$(get_secret_install_root_dir)/$(get_rel_root_user_gpg_homedir)"

  _install_root_user_gpg_identity "$root_gpg_dir"
}


install_liveenv_root_user_gpg_identity() {
  print_title_lvl3 "Installing device gpg root user identity sent by factory"

  ensure_expected_secret_install_root_dir_exists

  local root_gpg_dir
  root_gpg_dir="/$(get_rel_root_user_gpg_homedir)"

  _install_root_user_gpg_identity "$root_gpg_dir"
}


install_all_received_device_secrets() {
  print_title_lvl2 "Updating all device secrets sent by factory"

  install_device_host_ssh_identity
  install_device_root_user_ssh_identity
  install_device_root_user_gpg_identity

  install_liveenv_root_user_ssh_identity
  install_liveenv_root_user_gpg_identity

  # TODO: Wipe again unless debug mode.
  # wipe_factory_sent_secret_dir
}
