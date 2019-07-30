#!/usr/bin/env bash
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"
. "$common_install_libexec_dir/ssh.sh"
. "$common_install_libexec_dir/gpg.sh"


list_expected_device_host_ssh_key_types() {
  echo "rsa"
  echo "ed25519"
}


get_rel_host_ssh_homedir() {
  echo "etc/ssh"
}


list_expected_device_root_user_ssh_key_types() {
  echo "rsa"
}


get_rel_root_user_home() {
  echo "root"
}


get_rel_root_user_ssh_homedir() {
  echo "$(get_rel_root_user_home)/.ssh"
}


get_rel_root_user_ssh_rsa_public_key() {
  echo "$(get_rel_root_user_ssh_homedir)/id_rsa.pub"
}


_GPG_PRIVATE_KEY_BASENAME="private.gpg-key"
_GPG_PUBLIC_KEY_BASENAME="public.gpg-key"
_GPG_SUBKEYS_BASENAME="subkeys.gpg-keys"
_GPG_OTRUST_BASENAME="gpg-otrust"


get_gpg_private_key_basename() {
  echo "$_GPG_PRIVATE_KEY_BASENAME"
}


get_gpg_public_key_basename() {
  echo "$_GPG_PUBLIC_KEY_BASENAME"
}


get_gpg_subkeys_basename() {
  echo "$_GPG_SUBKEYS_BASENAME"
}


get_gpg_otrust_basename() {
  echo "$_GPG_OTRUST_BASENAME"
}


list_master_keypair_basenames() {
  out_exts=$(cat <<EOF
$(get_gpg_private_key_basename)
$(get_gpg_public_key_basename)
$(get_gpg_otrust_basename)
EOF
)
  echo "$out_exts"
}


list_master_keypair_with_subkeys_basenames() {
  out_exts=$(cat <<EOF
$(get_gpg_private_key_basename)
$(get_gpg_public_key_basename)
$(get_gpg_subkeys_basename)
$(get_gpg_otrust_basename)
EOF
)
  echo "$out_exts"
}


list_laptop_keypair_basenames() {
  out_exts=$(cat <<EOF
$(get_gpg_subkeys_basename)
$(get_gpg_otrust_basename)
EOF
)
  echo "$out_exts"
}


get_rel_root_user_gpg_homedir() {
  echo "$(get_rel_root_user_home)/.gnupg"
}


get_rel_gpg_public_key_filename() {
  echo "$(get_rel_root_user_gpg_homedir)/$(get_gpg_public_key_basename)"
}


list_rel_expected_host_ssh_key_files() {
  local rx_ssh_rel_homedir
  rx_ssh_rel_homedir="$(get_rel_host_ssh_homedir)"
  for kt in $(list_expected_device_host_ssh_key_types); do
    key_basename="$(get_host_key_basename_from_key_type "${kt}")"
    echo "$rx_ssh_rel_homedir/$key_basename"
    echo "$rx_ssh_rel_homedir/${key_basename}.pub"
  done
}


list_rel_expected_root_user_ssh_key_files() {
  local rx_ssh_rel_homedir
  rx_ssh_rel_homedir="$(get_rel_root_user_ssh_homedir)"
  for kt in $(list_expected_device_root_user_ssh_key_types); do
    echo "$rx_ssh_rel_homedir/id_${kt}"
    echo "$rx_ssh_rel_homedir/id_${kt}.pub"
  done
}


list_rel_expected_root_user_gpg_master_keypair_files() {
  local rx_rel_gpg_homedir
  rx_rel_gpg_homedir="$(get_rel_root_user_gpg_homedir)"

  for bn in $(list_master_keypair_basenames); do
    echo "$rx_rel_gpg_homedir/$bn"
  done
}


list_rel_expected_root_user_gpg_master_keypair_with_subkeys_files() {
  local rx_rel_gpg_homedir
  rx_rel_gpg_homedir="$(get_rel_root_user_gpg_homedir)"

  for bn in $(list_master_keypair_with_subkeys_basenames); do
    echo "$rx_rel_gpg_homedir/$bn"
  done
}


list_rel_expected_root_user_gpg_laptop_keypair_files() {
  local rx_rel_gpg_homedir
  rx_rel_gpg_homedir="$(get_rel_root_user_gpg_homedir)"

  for bn in $(list_laptop_keypair_basenames); do
    echo "$rx_rel_gpg_homedir/$bn"
  done
}
