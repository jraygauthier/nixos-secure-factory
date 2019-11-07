#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/tools.sh"

# From dependency libs.
common_install_libexec_dir="$(pkg-nixos-common-install-get-libexec-dir)"
. "$common_install_libexec_dir/gpg.sh"
. "$common_install_libexec_dir/device_secrets.sh"
. "$common_factory_install_libexec_dir/workspace_paths.sh"

get_gpg_sandbox_dir() {
  # TODO: Defaults to '~/.nixos-secure-factory/.gnupg'
  local ws_dir
  ws_dir="$(get_nixos_secure_factory_workspace_dir)"
  local default_sandbox_gpg_home_dir="$ws_dir/.gnupg"

  local gpg_home_sanbox_dir="${PKG_NIXOS_FACTORY_COMMON_INSTALL_SANDBOXED_GPG_HOME_DIR:-$default_sandbox_gpg_home_dir}"
  echo "$gpg_home_sanbox_dir"
}


is_gpg_home_sandboxed() {
  local gpg_home_sanbox_disable_value="${PKG_NIXOS_FACTORY_COMMON_INSTALL_SANDBOXED_GPG_HOME_DISABLE:-0}"
  # 1>&2 echo "gpg_home_sanbox_disable_value='$gpg_home_sanbox_disable_value'"
  ! test "1" == "${gpg_home_sanbox_disable_value:-0}"
}


get_default_gpg_home_dir() {
  if is_gpg_home_sandboxed; then
    # 1>&2 echo "get_default_gpg_home_dir -> sandboxed"
    local default_sandbox_gpg_home_dir
    default_sandbox_gpg_home_dir="$(get_gpg_sandbox_dir)"
    create_and_assign_proper_permissions_to_gpg_home_dir_lazy_and_silent "$default_sandbox_gpg_home_dir"
    echo "$default_sandbox_gpg_home_dir"
  else
    # 1>&2 echo "get_default_gpg_home_dir -> not sandboxed"
    echo "$HOME/.gnupg"
  fi
}

_run_sandboxed_gpg_pkg_exe() {
  local gpg_pkg_exe="${1?}"
  shift 1
  local gpg_home_dir
  gpg_home_dir="$(get_default_gpg_home_dir)"
  GNUPGHOME="$gpg_home_dir" \
    "$gpg_pkg_exe" "$@"
}


run_sandboxed_gpg() {
  _run_sandboxed_gpg_pkg_exe "nix-gpg" "$@"
}


run_sandboxed_gpgconf() {
  _run_sandboxed_gpg_pkg_exe "nix-gpgconf" "$@"
}


run_sandboxed_gpg_agent() {
_run_sandboxed_gpg_pkg_exe "nix-gpg-agent" "$@"
}


get_default_gpg_master_key_target_dir() {
  local default_tmp_dir="$TEMP"
  local tmp_dir="${1:-"$default_tmp_dir"}"
  local default_master_key_target_dir="$tmp_dir/gpg_tools/masterkeys"
  echo "$default_master_key_target_dir"
}


list_gpg_master_key_files() {
  local email="${1:-}"
  local default_tmp_dir="$TEMP"
  local tmp_dir="${2:-"$default_tmp_dir"}"
  local default_master_key_target_dir
  default_master_key_target_dir="$(get_default_gpg_master_key_target_dir "$tmp_dir")"
  local master_key_target_dir="${3:-"${default_master_key_target_dir}"}"

  if ! test -d "$master_key_target_dir"; then
    1>&2 echo "ERROR: No master key directory found at: '$master_key_target_dir'."
    return 1
  fi

  local master_key_files
  if test "" == "$email"; then
    master_key_files="$(find "$master_key_target_dir" -mindepth 1 -maxdepth 1)"
  else
    master_key_files="$(find "$master_key_target_dir" -mindepth 1 -maxdepth 1 | grep "$email")"
  fi

  if test "" == "$master_key_files"; then
    1>&2 echo "ERROR: No master key for email: '$email' found at: '$master_key_target_dir'."
    return 1
  fi

  echo "$master_key_files"
}


ensure_contains_gpg_master_key_files() {
  local email="${1:-}"
  local default_tmp_dir="$TEMP"
  local tmp_dir="${2:-"$default_tmp_dir"}"
  local default_master_key_target_dir
  default_master_key_target_dir="$(get_default_gpg_master_key_target_dir "$tmp_dir")"
  local master_key_target_dir="${3:-"${default_master_key_target_dir}"}"

  local master_key_files
  if ! master_key_files="$(list_gpg_master_key_files "$email" "$tmp_dir" "$master_key_target_dir")"; then
    exit 1
  fi

  master_key_file_exts=$(cat <<EOF
$(get_gpg_private_key_basename)
$(get_gpg_public_key_basename)
$(get_gpg_subkeys_basename)
$(get_gpg_otrust_basename)
EOF
)

  if test "" == "$email"; then
    for f_ext in $master_key_file_exts; do
      if ! echo "$master_key_files" | grep -q "\.${f_ext}"; then
        1>&2 echo "Cannot find any master key file with extension: '$f_ext' under '$master_key_target_dir'."
      fi
    done
  else
    for f_ext in $master_key_file_exts; do
      local f="$master_key_target_dir/<${email}>.${f_ext}"
      if ! test -f "$f"; then
        1>&2 echo "Missing master key file: '$f'."
      fi
    done
  fi

}


list_gpg_public_key_ids_w_email() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local gpg_email_or_id="${2:-}"
  if ! test -d "$gpg_home_dir"; then
    return 1
  fi

  # "fpr" stand for fingerprint.
  local out_keys
  if test "" == "$gpg_email_or_id"; then
    out_keys="$(nix-gpg --homedir "$gpg_home_dir" --list-public-keys \
      --list-options show-only-fpr-mbox)"
  else
    out_keys="$(nix-gpg --homedir "$gpg_home_dir" --list-public-keys \
      --list-options show-only-fpr-mbox | grep "$gpg_email_or_id")"
  fi

  if test "" == "$out_keys"; then
    return 1
  fi

  echo "$out_keys"
}


list_gpg_public_key_ids() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  list_gpg_public_key_ids_w_email "$gpg_home_dir" "$email" | awk '{ print $1 }'
}


list_gpg_public_emails() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"

  if ! test -d "$gpg_home_dir"; then
    return 1
  fi

  # "fpr" stand for fingerprint.
  nix-gpg --homedir "$gpg_home_dir" --list-public-keys \
    --list-options show-only-fpr-mbox | awk '{ print $2 }'
}


list_gpg_secret_key_ids_w_email() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  local passphrase="${3:-}"

  # "fpr" stand for fingerprint.
  local out_keys
  if test "" == "$email"; then
    out_keys="$(nix-gpg --homedir "$gpg_home_dir" --passphrase "$passphrase" \
      --list-options show-only-fpr-mbox --list-secret-keys)"
  else
    out_keys="$(nix-gpg --homedir "$gpg_home_dir" --passphrase "$passphrase" \
      --list-options show-only-fpr-mbox --list-secret-keys | grep "$email")"
  fi

  if test "" == "$out_keys"; then
    return 1
  fi

  echo "$out_keys"
}


list_gpg_secret_key_ids() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  local passphrase="${3:-}"

  list_gpg_secret_key_ids_w_email "$gpg_home_dir" "$email" "$passphrase"  | awk '{ print $1 }'
}


print_gpg_secret_keys() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"

  if ! test -d "$gpg_home_dir"; then
    return 1
  fi

  if test "" == "$email"; then
    nix-gpg --homedir "$gpg_home_dir" --passphrase "$passphrase" \
      --list-secret-keys
  else
    nix-gpg --homedir "$gpg_home_dir" --passphrase "$passphrase" \
      --list-secret-keys | grep "$email"
  fi
}


print_gpg_public_keys() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"

  if ! test -d "$gpg_home_dir"; then
    return 1
  fi

  if test "" == "$email"; then
    nix-gpg --homedir "$gpg_home_dir" --list-public-keys
  else
    nix-gpg --homedir "$gpg_home_dir" --list-public-keys "$email"
  fi
}


is_gpg_identity_present() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  local passphrase="${3:-}"

  list_gpg_public_key_ids "$gpg_home_dir" "$email" > /dev/null || \
    list_gpg_secret_key_ids "$gpg_home_dir" "$email" "$passphrase"
}


ensure_no_gpg_identity_present() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  local passphrase="${3:-}"

  if is_gpg_identity_present "$gpg_home_dir" "$email" "$passphrase"; then
    1>&2 echo "ERROR: User with gpghomedir of '$gpg_home_dir' already has a gpg identity for email '$email'."
    1>&2 echo "  Please rm the gpg identity by running ('factory-gpg-rm-identity \"$email\"') and re-run this."
    1>&2 echo "  The following keys were in the way:"
    1>&2 print_gpg_public_keys "$gpg_home_dir" "$email" | awk '{print "    " $0}'


    exit 1
  fi
}


rm_gpg_secret_keys() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  local passphrase="${3:-}"

  local secret_keys_w_email
  if ! secret_keys_w_email="$(list_gpg_secret_key_ids_w_email "$gpg_home_dir" "$email" "$passphrase")"; then
    1>&2 echo "WARNING: No secret keys to remove from gpghomedir: '$gpg_home_dir' with an email of '$email'."
    return 0
  fi

  echo "Will remove the following secret keys from gpghomedir '$gpg_home_dir':"
  echo "$secret_keys_w_email" | \
  while read k eml; do
    echo " -> key: '$k', email: '$eml'"
  done

  test "1" == "${GPG_TOOLS_PROMPT_BEFORE_IDENTITY_REMOVAL:-}" && \
    prompt_for_user_approval

  echo "$secret_keys_w_email" | \
  while read k eml; do
    echo "Removing gpghomedir: '$gpg_home_dir', key: '$k', email: '$eml'."
    nix-gpg --homedir "$gpg_home_dir" \
      --batch --passphrase "$passphrase" --yes \
      --delete-secret-and-public-keys "$k"
  done
}


rm_gpg_public_keys() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local email="${2:-}"
  local passphrase="${3:-}"

  local public_keys_w_email
  if ! public_keys_w_email="$(list_gpg_public_key_ids_w_email "$gpg_home_dir" "$email")"; then
    1>&2 echo "WARNING: No public keys to remove from gpghomedir: '$gpg_home_dir' with an email of '$email'."
    return 0
  fi

  echo "Will remove the following public keys from gpghomedir '$gpg_home_dir':"
  echo "$public_keys_w_email" | \
  while read k eml; do
    echo " -> key: '$k', email: '$eml'"
  done

  test "1" == "${GPG_TOOLS_PROMPT_BEFORE_IDENTITY_REMOVAL:-}" && \
    prompt_for_user_approval

  echo "$public_keys_w_email" | \
  while read k eml; do
    echo "Removing gpghomedir: '$gpg_home_dir', key: '$k', email: '$eml'."
    nix-gpg --homedir "$gpg_home_dir" \
      --batch --passphrase "$passphrase" --yes --delete-secret-and-public-keys "$k"
  done
}


rm_gpg_identity() {
  rm_gpg_secret_keys "${1:-}" "${2:-}" "${3:-}" && \
    rm_gpg_public_keys "${1:-}" "${2:-}" "${3:-}"
}


ensure_gpg_has_single_secret_key() {
  local gpghomedir="$1"
  local key_email="$2"

  if ! ids="$(list_gpg_secret_key_ids "$gpghomedir" "$key_email" "$passphrase" | wc -l)"; then
    1>&2 echo "ERROR: No secret key detected for \`email=${key_email}\` in \`gpghomedir=${gpghomedir}\`."
    exit 1
  fi

  if ! test "1" -eq "$ids"; then
    1>&2 echo "ERROR: More the a single secret key detected for \`email=${key_email}\` in \`gpghomedir=${gpghomedir}\`."
    exit 1
  fi

  true
}


create_gpg_master_identity_with_signing_subkey() {
  local target_gpg_home_dir="$1"
  local email="$2"
  local user_name="$3"
  local passphrase="${4:-}"

  local expire_in="1y"

  printf -- "\n"
  printf -- "Creating gpg identity with signing subkey\n"
  printf -- "------------------------------------------\n\n"

  create_and_assign_proper_permissions_to_gpg_home_dir "$target_gpg_home_dir"



  local _GPG_MASTER_KEYS_BATCH
  _GPG_MASTER_KEYS_BATCH=$(cat <<EOF
# Use for gpg key without passwords
%no-protection
Key-Type: RSA
Key-Length: 4096
Key-Usage: cert, sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: cert, encrypt
Name-Real: ${user_name}
Name-Email: ${email}
Expire-Date: ${expire_in}
Preferences: SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
EOF
)

  echo "$_GPG_MASTER_KEYS_BATCH" | nix-gpg --homedir "$target_gpg_home_dir" \
    --passphrase "$passphrase" --batch \
    --full-generate-key -

  ensure_gpg_has_single_secret_key "$target_gpg_home_dir" "$email"

  local master_key_fingerprint
  master_key_fingerprint="$(list_gpg_secret_key_ids "$target_gpg_home_dir" "$email" "$passphrase" | head -n 1)"
  echo "master_key_fingerprint=\"$master_key_fingerprint\""

  nix-gpg --homedir "$target_gpg_home_dir" \
    --passphrase "$passphrase" \
    --list-secret-keys
  nix-gpg --homedir "$target_gpg_home_dir" \
    --batch --passphrase "$passphrase" --quick-add-key "$master_key_fingerprint" rsa sign 1y
}


wipe_gpg_exported_files_dir() {
  local common_prefix="$1"
  rm -fr "$common_prefix"
}


create_gpg_parentdir_for_exported_file() {
  local out_filename="$1"
  local parent_dir
  parent_dir="$(dirname "$out_filename")"
  mkdir -p -m 0700 "$parent_dir"
}


export_gpg_public_key_file() {
  local out_filename="$1"
  local in_gpg_homedir="$2"
  local email="$3"
  local passphrase="${4:-}"

  echo "Exporting gpg public key to '$out_filename'."
  create_gpg_parentdir_for_exported_file "$out_filename"

  nix-gpg --homedir "$in_gpg_homedir" \
    --batch --passphrase "$passphrase" \
    --export --armor "$email" \
    > "$out_filename"

  chmod 0700 "$out_filename"
}


export_gpg_private_key_file() {
  local out_filename="$1"
  local in_gpg_homedir="$2"
  local email="$3"
  local passphrase="${4:-}"

  echo "Exporting gpg private key to '$out_filename'."
  create_gpg_parentdir_for_exported_file "$out_filename"

  if test "" == "$passphrase"; then
    nix-gpg --homedir "$in_gpg_homedir" \
      --batch --passphrase "$passphrase" \
      --export-secret-keys --armor "$email" \
      > "$out_filename"
  else
    # For some reason, when "passphrase" is non empty, when using "--export-secret-keys", we're prompted
    # for a password by gui even tough "--passphrase" is specified. This is a workaround.
    echo "$passphrase" | nix-gpg --homedir "$in_gpg_homedir" \
      --batch --pinentry-mode loopback --yes --no-tty --passphrase-fd 0 \
      --export-secret-keys --armor "$email" \
      > "$out_filename"
  fi

  chmod 0700 "$out_filename"
}


export_gpg_otrust_file() {
  local out_filename="$1"
  local in_gpg_homedir="$2"
  local email="$3"
  local passphrase="${4:-}"

  echo "Exporting gpg owner trust to '$out_filename'."
  create_gpg_parentdir_for_exported_file "$out_filename"

  nix-gpg --homedir "$in_gpg_homedir" \
    --export-ownertrust > "$out_filename"

  chmod 0700 "$out_filename"
}


export_gpg_subkeys_file() {
  local out_filename="$1"
  local in_gpg_homedir="$2"
  local email="$3"
  local passphrase="${4:-}"

  echo "Exporting gpg subkes to '$out_filename'."
  create_gpg_parentdir_for_exported_file "$out_filename"

  if test "" == "$passphrase"; then
    nix-gpg --homedir "$in_gpg_homedir" \
      --batch --passphrase "$passphrase" \
      --export-secret-subkeys "$email" \
      > "$out_filename"
  else
    # For some reason, when "passphrase" is non empty, when using "--export-secret-subkeys", we're prompted
    # for a password by gui even tough "--passphrase" is specified. This is a workaround.
    echo "$passphrase" | nix-gpg --homedir "$in_gpg_homedir" \
      --batch --pinentry-mode loopback --yes --no-tty --passphrase-fd 0 \
      --export-secret-subkeys "$email" \
      > "$out_filename"
  fi

  chmod 0700 "$out_filename"
}


export_gpg_master_keys_to_individual_files() {
  printf -- "\n"
  printf -- "Exporting gpg master key to files\n"
  printf -- "---------------------------------\n\n"

  local out_public_key="$1"
  local out_private_key="$2"
  local out_owner_trust="$3"
  local out_secret_keys="$4"
  local in_gpg_homedir="$5"
  local email="$6"
  local passphrase="${7:-}"

  export_gpg_public_key_file \
    "$out_public_key" "$in_gpg_homedir" "$email" "$passphrase"
  export_gpg_private_key_file \
    "$out_private_key" "$in_gpg_homedir" "$email" "$passphrase"
  export_gpg_otrust_file \
    "$out_owner_trust" "$in_gpg_homedir" "$email" "$passphrase"
  export_gpg_subkeys_file \
    "$out_secret_keys" "$in_gpg_homedir" "$email" "$passphrase"
}


export_gpg_master_keys_to_dir() {
  printf -- "\n"
  printf -- "Exporting gpg master key to dir\n"
  printf -- "-------------------------------\n\n"

  local out_dir="$1"
  local in_gpg_homedir="$2"
  local email="$3"
  local passphrase="${4:-}"
  local common_basename_prefix="${5:-}"

  wipe_gpg_exported_files_dir "$out_dir"

  out_prefix="$out_dir/$common_basename_prefix"

  export_gpg_master_keys_to_individual_files \
    "${out_prefix}public.gpg-key" \
    "${out_prefix}private.gpg-key" \
    "${out_prefix}gpg-otrust" \
    "${out_prefix}subkeys.gpg-keys" \
    "$in_gpg_homedir" "$email" "$passphrase"
}


# TODO: Remove, not used.
list_gpg_agent_files_to_rm() {
  local out
  local gpg_agent_home="$(gpgconf --list-dirs | grep homedir | awk -F':' '{ print $2}')"
  out="$(find "$gpg_agent_home" -mindepth 1 -maxdepth 1 | grep '\-migrated$')"
  echo "$out"
}


# TODO: Remove, not used.
run_gpg_agent_reset_hack() {
  gpgconf --kill gpg-agent
  local files_to_rm
  files_to_rm="$(list_gpg_agent_files_to_rm)"
  echo "$files_to_rm" | xargs -r rm -- -r
  gpgconf --kill gpg-agent
}


create_gpg_master_keypair_and_export_to_dir() {
  local out_dir="$1"
  local email="$2"
  local user_name="$3"
  local passphrase="${4:-}"
  local default_tmp_dir="$TEMP"
  local tmp_dir="${5:-"$default_tmp_dir"}"
  local common_basename_prefix="${6:-}"

  printf -- "\n"
  printf -- "Creating gpg master keypair exporting to dir\n"
  printf -- "--------------------------------------------\n\n"

  local tmp_gpg_home="$tmp_dir/gpg_tools/tmp_home"

  # export GNUPGHOME="$tmp_gpg_home"
  wipe_gpg_home_dir "$tmp_gpg_home"

  create_gpg_master_identity_with_signing_subkey "$tmp_gpg_home" "$email" "$user_name"

  export_gpg_master_keys_to_dir \
    "$out_dir" "$tmp_gpg_home" \
    "$email" "$passphrase" "$common_basename_prefix"
}


create_gpg_master_keypair_and_import_laptop_keypair_to_target_homedir() {
  local target_gpg_home_dir="$1"
  local email="$2"
  local user_name="$3"
  local passphrase="$4"
  local default_tmp_dir="$TEMP"
  local tmp_dir="${5:-"$default_tmp_dir"}"
  local default_master_key_target_dir
  default_master_key_target_dir="$(get_default_gpg_master_key_target_dir "$tmp_dir")"
  local master_key_target_dir="${6:-"${default_master_key_target_dir}"}"

  printf -- "\n"
  printf -- "Creating gpg master keypair importing only laptop keypair to homedir\n"
  printf -- "--------------------------------------------------------------------\n\n"

  ensure_no_gpg_identity_present \
    "$target_gpg_home_dir" "$email" \
    "$passphrase" "$passphrase"

  common_basename_prefix="<${email}>."

  create_gpg_master_keypair_and_export_to_dir \
    "$master_key_target_dir" \
    "$email" \
    "$user_name" \
    "$passphrase" \
    "$tmp_dir" \
    "$common_basename_prefix"

  out_prefix="$master_key_target_dir/$common_basename_prefix"

  import_gpg_subkeys \
    "$target_gpg_home_dir" \
    "${out_prefix}$(get_gpg_subkeys_basename)" \
    "${out_prefix}$(get_gpg_otrust_basename)" \
    "$passphrase"
}


rm_current_user_gpg_identity() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  rm_gpg_identity "$defaul_gpg_home_dir" "$1" "$2"
}


create_current_user_gpg_identity() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  create_gpg_master_keypair_and_import_laptop_keypair_to_target_homedir \
    "$defaul_gpg_home_dir" \
    "$1" "$2" "$3" "${4:-}" "${5:-}"
}


copy_gpg_public_key_to_clipboard() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  local gpg_home_dir="${1:-"$defaul_gpg_home_dir"}"
  local gpg_email_or_id="${2:-}"

  local public_keys_ids
  if ! public_keys_ids="$(list_gpg_public_key_ids_w_email "$gpg_home_dir" "$gpg_email_or_id")"; then
    1>&2 echo "ERROR: No public keys to for gpg_email_or_id '$gpg_email_or_id' found in '$gpg_home_dir'."
    return 1
  fi

  local selected_public_key_id
  selected_public_key_id="$(echo "$public_keys_ids" | head -n 1 | awk '{ print $1 }')"

  local pkey_count
  pkey_count="$(echo "$public_keys_ids" | wc -l)"
  if test "$pkey_count" -gt "1"; then
    1>&2 echo "WARNING: More than a single key for gpg_email_or_id '$gpg_email_or_id' found in '$gpg_home_dir':"
    1>&2 echo "$public_keys_ids" | awk '{ print $1 }'
    1>&2 echo " -> Fallbacking to the first one: '$selected_public_key_id'."
    return 1
  fi

  echo "selected_public_key_id='$selected_public_key_id'"

  local selected_public_key
  selected_public_key="$(nix-gpg --homedir "$gpg_home_dir" --armor --export "$selected_public_key_id")"

  echo "$selected_public_key" \
    | DISPLAY="${DISPLAY:-":0"}" xclip -selection clipboard
  echo "'$selected_public_key_id' for gpg_email_or_id '$gpg_email_or_id' has been placed in your clipboard. Paste it where you need."
  printf -- "\n"
}


copy_current_user_gpg_public_key_to_clipboard() {
  local defaul_gpg_home_dir
  defaul_gpg_home_dir="$(get_default_gpg_home_dir)"
  copy_gpg_public_key_to_clipboard "$defaul_gpg_home_dir" "$1"
}


get_gpg_keyring_location() {
  get_gpg_keyring_location_generic "factory-gpg"
}



get_email_for_gpg_id() {
  local gpg_id_or_email="$1"
  get_email_for_gpg_id_generic "factory-gpg" "$gpg_id_or_email"
}


import_gpg_secret_and_public_keys_from_user_home_keyring() {
  local gpg_id_or_email="${1:-}"

  local source_gpg_args=()
  local target_gpg_args=()
  transfer_gpg_secret_and_public_keys_from_keyring_to_keyring \
    "gpg" "source_gpg_args" \
    "factory-gpg" "target_gpg_args" \
    "$gpg_id_or_email"
}


export_gpg_secret_and_public_keys_to_user_home_keyring() {
  local gpg_id_or_email="${1:-}"

  local source_gpg_args=()
  local target_gpg_args=()
  transfer_gpg_secret_and_public_keys_from_keyring_to_keyring \
    "factory-gpg" "source_gpg_args" \
    "gpg" "target_gpg_args" \
    "$gpg_id_or_email"
}


import_gpg_public_key_from_user_home_keyring() {
  local gpg_id_or_email="${1:-}"

  local source_gpg_args=()
  local target_gpg_args=()
  transfer_gpg_public_key_from_keyring_to_keyring \
    "gpg" "source_gpg_args" \
    "factory-gpg" "target_gpg_args" \
    "$gpg_id_or_email"
}


export_gpg_public_key_to_user_home_keyring() {
  local gpg_id_or_email="${1:-}"

  local source_gpg_args=()
  local target_gpg_args=()
  transfer_gpg_public_key_from_keyring_to_keyring \
    "factory-gpg" "source_gpg_args" \
    "gpg" "target_gpg_args" \
    "$gpg_id_or_email"
}


select_unique_gpg_id() {
  local -n _out_ref="$1"
  local gpg_id_or_email="${2:-}"

  local key_type="public"
  local matching_gpg_id_inner_1=""
  local source_gpg_args=()
  select_unique_gpg_key_in_keyring \
    "matching_gpg_id_inner_1" "factory-gpg" "source_gpg_args" "$key_type" "$gpg_id_or_email"
  _out_ref="$matching_gpg_id_inner_1"
}


select_unique_gpg_id_w_secrets() {
  local -n _out_ref="$1"
  local gpg_id_or_email="${2:-}"
  _out_ref=""


  local key_type="secrets"
  local matching_gpg_id_inner_1=""
  local source_gpg_args=()
  select_unique_gpg_key_in_keyring \
    "matching_gpg_id_inner_1" "factory-gpg" "source_gpg_args" "$key_type" "$gpg_id_or_email"
  _out_ref="$matching_gpg_id_inner_1"
}


delete_gpg_public_key() {
  local gpg_id_or_email="${1:-}"
  1>&2 echo "TODO: Implement"
  false
}


delete_gpg_secret_keys() {
  local gpg_id_or_email="${1:-}"
  1>&2 echo "TODO: Implement"
  false
}


delete_gpg_secret_and_public_keys() {
  local gpg_id_or_email="${1:-}"
  1>&2 echo "TODO: Implement"
  false
}


list_gpg_id_w_email_from_armored_pub_key_stdin() {
  local gpg_ids_w_email
  if ! gpg_ids_w_email="$(cat - \
      | factory-gpg --import-options show-only --list-options show-only-fpr-mbox  --import)"; then
    1>&2 echo "ERROR: No valid pgp data found in stdin armored public key."
    return 1
  fi

  echo "$gpg_ids_w_email"
}


list_gpg_id_from_armored_pub_key_stdin() {
  list_gpg_id_w_email_from_armored_pub_key_stdin | awk '{ print $1}'
}


get_unique_gpg_id_w_email_from_armored_pub_key_stdin() {
  local gpg_ids_w_email
  gpg_ids_w_email="$(cat - | list_gpg_id_w_email_from_armored_pub_key_stdin)"

  if ! is_mem_sh_stream_singleton "$gpg_ids_w_email"; then
    1>&2 echo "ERROR: More than one gpg public key was found in stdin armored public key. "
    1>&2 printf "  Please provide a single identity. Here's what was found: ''\n%s\n''\n" "$gpg_ids_w_email"
    return 1
  fi

  local unique_gpg_id_w_email_from_armored_pubkey_file
  unique_gpg_id_w_email_from_armored_pubkey_file="$(echo "$gpg_ids_w_email" | head -n 1)" \
    || return 1

  echo "$unique_gpg_id_w_email_from_armored_pubkey_file"
}


get_unique_gpg_id_from_armored_pub_key_stdin() {
  local unique_gpg_id_from_armored_pubkey_file
  unique_gpg_id_from_armored_pubkey_file="$(\
    cat - | get_unique_gpg_id_w_email_from_armored_pub_key_stdin | awk '{ printf $1 }')" \
      || return 1

  echo "$unique_gpg_id_from_armored_pubkey_file"
}


import_from_armored_pub_key_stdin() {
  cat - | factory-gpg --import
}
