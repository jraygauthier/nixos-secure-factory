#!/usr/bin/env bash
common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"


wipe_gpg_home_dir() {
  printf -- "\n"
  printf -- "Wiping gpg home dir\n"
  printf -- "-------------------\n\n"

  local target_gpg_home_dir="$1"
  echo "rm -fr '$target_gpg_home_dir'"
  rm -fr "$target_gpg_home_dir"
}


create_and_assign_proper_permissions_to_gpg_home_dir() {
  printf -- "\n"
  printf -- "Creating fresh gpg homedir or assigning proper permission to existing.\n"
  printf -- "----------------------------------------------------------------------\n\n"

  local target_gpg_home_dir="$1"

  if test -d "$target_gpg_home_dir"; then
    # Ensure all required directories exists and have proper permissions.
    echo "Updating permission in existing gpghome at: '$target_gpg_home_dir'."
    chmod 700 "$target_gpg_home_dir"
    mkdir -p "$target_gpg_home_dir/private-keys-v1.d"
    chmod 700 "$target_gpg_home_dir/private-keys-v1.d"
  else
    echo "Creating initial gpghome at: '$target_gpg_home_dir'."
    mkdir -m 700 -p "$target_gpg_home_dir"
    mkdir -m 700 -p "$target_gpg_home_dir/private-keys-v1.d"
    # Force automated creation of missing files.
    gpg --homedir "$target_gpg_home_dir" --list-keys
  fi
}


import_gpg_subkeys() {
  printf -- "\n"
  printf -- "Importing gpg subkeys to target gpg home\n"
  printf -- "----------------------------------------\n\n"

  local target_gpg_home_dir="$1"
  local exported_subkeys_file="$2"
  local exported_otrust_file="$3"
  local passphrase="${4:-}"

  create_and_assign_proper_permissions_to_gpg_home_dir "$target_gpg_home_dir"

  # --passphrase "$passphrase"
  # echo "$passphrase" | gpg --homedir "$target_gpg_home_dir" \
  #   --batch  --pinentry-mode loopback --yes --no-tty --passphrase-fd 0  \
  #   --import "$exported_subkeys_file"

  echo "Importing subkeys from '$exported_subkeys_file'."
  gpg --homedir "$target_gpg_home_dir" \
    --batch  --passphrase "$passphrase" \
    --import "$exported_subkeys_file"

  echo "Importing owner trust from '$exported_otrust_file'."
  gpg --homedir "$target_gpg_home_dir" < "$exported_otrust_file" \
    --import-ownertrust

  echo "Keys after --import subkeys:"
  gpg --homedir "$target_gpg_home_dir" --list-secret-keys
}
