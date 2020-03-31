#!/usr/bin/env bash

data_deploy_sh_lib_dir="$(pkg-nixos-sf-data-deploy-tools-get-sh-lib-dir)"
. "$data_deploy_sh_lib_dir/deploy-tools.sh"


print_file_extensions() {
  local file="${1?}"
  echo "$file" | tr '/' '\n' | tail -n -1 | cut -s -d. -f2-
}


print_last_file_extension_from_exts() {
  local file_exts="${1?}"
  echo "$file_exts" | awk -F. 'NF < 1 { exit 1 } { print $NF }'
}


print_2nd_last_file_extension_from_exts() {
  local file_exts="${1?}"
  echo "$file_exts" | awk -F. 'NF < 2 { exit 1 } { print $(NF - 1) }'
}


ensure_has_gpg_extension_from_exts() {
  local file_exts="${1?}"

  local gnu_ext
  if gnu_ext="$(print_last_file_extension_from_exts "$file_exts")" \
      && [[ "gpg" == "$gnu_ext" ]] ; then
    true
  else
    1>&2 printf \
      "ERROR: %s: unexpected last extension '%s'.\n -> Expected 'gpg'." \
      "${FUNCNAME[0]}" "$gnu_ext"
    exit 1
  fi
}


ensure_has_gpg_extension() {
  local file="${1?}"

  local file_exts
  file_exts="$(print_file_extensions "$file")" || return 1
  ensure_has_gpg_extension_from_exts "$file_exts" || return 1
}


is_pgp_file_b64_encoded() {
  local file_exts="${1?}"
  local b64_encoded="${2:-}"

  local opt_b64_ext
  if [[ "1" == "$b64_encoded" ]]; then
    true
  elif [[ "0" == "$b64_encoded" ]]; then
    false
  elif [[ "" == "$b64_encoded" ]]; then
    if opt_b64_ext="$(print_2nd_last_file_extension_from_exts "$file_exts")" \
        && [[ "b64" == "$opt_b64_ext" ]]; then
      true
    else
      false
    fi
  else
    1>&2 printf \
      "ERROR: %s: unexpected 'b64_encoded' argument value: '%s'.\n -> Expected '1', '0' or ''." \
      "${FUNCNAME[0]}" "$b64_encoded"
    exit 1
  fi
}


build_gpg_argsa() {
  local -n _out_gpg_arg_a="${1?}"
  local src_file="${2?}"
  # shellcheck disable=SC2034
  _out_gpg_arg_a=( --batch --pinentry-mode loopback --yes --quiet --decrypt "$src_file" )
}


decrypt_gpg_base64_encoded_file_to_stdout() {
  local src_file="${1?}"
  local gpg_args
  build_gpg_argsa "gpg_args" "$src_file"
  gpg "${gpg_args[@]}" | base64 -d || return 1
}


deploy_gpg_base64_encoded_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  local gpg_args
  build_gpg_argsa "gpg_args" "$src_file"
  echo gpg "${gpg_args[@]}" "|" base64 "-d" ">" "$tgt_file"
  decrypt_gpg_base64_encoded_file_to_stdout \
    "$src_file" > "$tgt_file" || return 1
}


deploy_gpg_base64_encoded_file_to_dev_null() {
  local src_file="${1?}"
  local tgt_file="/dev/null"
  deploy_gpg_base64_encoded_file "$src_file" "$tgt_file"
}


decrypt_gpg_file_to_stdout() {
  local src_file="${1?}"
  local gpg_args
  build_gpg_argsa "gpg_args" "$src_file"
  gpg "${gpg_args[@]}" || return 1
}


deploy_gpg_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  local gpg_args
  build_gpg_argsa "gpg_args" "$src_file"
  echo gpg "${gpg_args[@]}" ">" "$tgt_file"
  decrypt_gpg_file_to_stdout "$src_file" > "$tgt_file" || return 1
}


deploy_gpg_file_to_dev_null() {
  local src_file="${1?}"
  local tgt_file="/dev/null"
  deploy_gpg_file "$src_file" "$tgt_file"
}


deploy_pgp_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  local b64_encoded="${3:-}"

  local file_exts
  file_exts="$(print_file_extensions "$src_file")" || return 1

  ensure_has_gpg_extension_from_exts "$file_exts" || return 1

  if is_pgp_file_b64_encoded "$file_exts" "$b64_encoded"; then
    # Has been base64 encoded before encryption.
    # We want to rule out any gpg issues before writing the file.
    deploy_gpg_base64_encoded_file_to_dev_null "$src_file" || return 1
    # We do the actual job here.
    deploy_gpg_base64_encoded_file "$src_file" "$tgt_file" || return 1
  else
    # Has not been base64 encoded. Only decrypt.
    # We want to rule out any gpg issues before writing the file.
    deploy_gpg_file_to_dev_null "$src_file" || return 1
    # We do the actual job here.
    deploy_gpg_file "$src_file" "$tgt_file" || return 1
  fi
}


deploy_pgp_file_w_inherited_permissions() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  local b64_encoded="${3:-}"

  local tgt_dir
  tgt_dir="$(dirname "$tgt_file")"
  mkdir_w_inherited_permissions "$tgt_dir" || return 1
  deploy_pgp_file "$src_file" "$tgt_file" "$b64_encoded" || return 1
  inherit_permissions_from "$tgt_file" "$tgt_dir"
}
