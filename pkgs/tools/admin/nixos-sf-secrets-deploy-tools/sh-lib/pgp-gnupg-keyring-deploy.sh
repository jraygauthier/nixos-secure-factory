#!/usr/bin/env bash

sh_lib_dir="$(pkg-nixos-sf-secrets-deploy-tools-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/pgp-file-deploy.sh
. "$sh_lib_dir/pgp-file-deploy.sh"


_build_import_gpg_keys_file_argsa() {
  # shellcheck disable=SC2178
  local -n _out_gpg_arg_a="${1?}"
  local src_file="${2?}"
  local tgt_gnupg_homedir="${3?}"

  local _home_dir_arg_a
  _build_gpg_home_dir_argsa "_home_dir_arg_a" "$tgt_gnupg_homedir"

  # shellcheck disable=SC2034
  _out_gpg_arg_a=( \
    "${_home_dir_arg_a[@]}" \
    --batch --yes \
    --import "$src_file" \
  )
}


_import_gpg_keys_file() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"

  local gpg_args
  _build_import_gpg_keys_file_argsa \
    "gpg_args" "$src_file" "$tgt_gnupg_homedir" || return 1
  gpg "${gpg_args[@]}" || return 1
}


_print_pipe_expr_import_gpg_keys_file() {
  # Must print expr equivalent to '_import_gpg_keys_file' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_gnupg_homedir="${4?}"

  local gpg_args
  _build_import_gpg_keys_file_argsa \
    "gpg_args" "$src_file" "$tgt_gnupg_homedir" || return 1
  _print_pipe_expr_gpg "$prefix" "$suffix" "${gpg_args[@]}"
}


_deploy_gpg_keys() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"
  local b64_enc="${3?}"

  _deploy_gpg_file "$src_file" "-" "$b64_enc" \
    | _import_gpg_keys_file "-" "$tgt_gnupg_homedir" \
      || return 1
}


_print_pipe_expr_deploy_gpg_keys() {
  # Must print expr equivalent to '_deploy_gpg_keys' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_gnupg_homedir="${4?}"
  local b64_enc="${5?}"

  _print_pipe_expr_deploy_gpg_file \
    "$prefix" "" "$src_file" "-" "$b64_enc" || return 1
  _print_pipe_expr_import_gpg_keys_file \
    " | " "$suffix" "-" "$tgt_gnupg_homedir" || return 1
}


_deploy_v_gpg_keys() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"
  local b64_enc="${3?}"

  _print_pipe_expr_deploy_gpg_keys \
    "$ " "\n" "$src_file" "$tgt_gnupg_homedir" "$b64_enc" || return 1
  _deploy_gpg_keys \
    "$src_file" "$tgt_gnupg_homedir" "$b64_enc" || return 1
}


deploy_pgp_gnupg_keys() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"
  local b64_enc="${3:-}"

  # TODO: 'b64_enc' as optiona arg. Use global ass. array to propage.
  # TODO: Support gpp '--gpg-homedir' option arg. Use global array to propagate.

  # We want to test the decryption pipeline beforehand,
  # in order to prevent any corruption of the keyring.
  # This might be longer but is however safer.
  # TODO: Optimize when secure ramfs is available on
  # the target system.
  _deploy_v_gpg_file \
    "$src_file" "/dev/null" "$b64_enc" || return 1
  # Actual keyring import here.
  _deploy_v_gpg_keys \
    "$src_file" "$tgt_gnupg_homedir" "$b64_enc" || return 1
}


_import_gpg_otrust_from_stdin() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"

  local gpg_args
  _build_import_gpg_otrust_from_stdin_argsa \
    "gpg_args" "$src_file" "$tgt_gnupg_homedir" || return 1
  gpg "${gpg_args[@]}" || return 1
}


_print_pipe_expr_import_gpg_otrust_from_stdin() {
  # Must print expr equivalent to '_import_gpg_otrust_from_stdin' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_gnupg_homedir="${4?}"

  local gpg_args
  _build_import_gpg_otrust_from_stdin_argsa \
    "gpg_args" "$src_file" "$tgt_gnupg_homedir" || return 1
  _print_pipe_expr_gpg "$prefix" "$suffix" "${gpg_args[@]}"
}



_build_import_gpg_otrust_from_stdin_argsa() {
  # shellcheck disable=SC2178
  local -n _out_gpg_arg_a="${1?}"
  local src_file="${2?}"
  local tgt_gnupg_homedir="${3?}"

  local _home_dir_arg_a
  _build_gpg_home_dir_argsa "_home_dir_arg_a" "$tgt_gnupg_homedir"

  # shellcheck disable=SC2034
  _out_gpg_arg_a=( \
    "${_home_dir_arg_a[@]}" \
    --batch --yes \
    --import-ownertrust "$src_file" \
  )
}


_filter_out_gpg_otrust_comments() {
  grep -E -v '^#'
}


_parse_gpg_otrust_key_field() {
   _filter_out_gpg_otrust_comments | awk -F: '{ print $1 }'
}


_filter_out_gpg_otrust_inexistant_keys() {
  local gpg_homedir="${1?}"
  while read -r tdb_line; do
    local tdb_key
    tdb_key="$(echo "$tdb_line" | _parse_gpg_otrust_key_field)"
    # echo "$tdb_key"
    if ! gpg --homedir "$gpg_homedir" -k "$tdb_key" &>/dev/null; then
      _warn_printf \
        "Cannot deploy otrust line '%s'. Key not part of '%s' gnupg keyring. Skipping.\n" \
        "$tdb_line" "$gpg_homedir"
      continue
    fi
    echo "$tdb_line"
  done < <(cat - | _filter_out_gpg_otrust_comments)
}

_print_pipe_expr_filter_out_gpg_otrust_inexistant_keys() {
  local prefix="${1?}"
  local suffix="${2?}"
  local tgt_gnupg_homedir="${3?}"
  printf "%b" "$prefix"
  printf "_filter_out_gpg_otrust_inexistant_keys %q" "$src_file"
  printf "%b" "$suffix"
}


_deploy_gpg_otrust() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"
  local b64_enc="${3?}"
  _deploy_gpg_file "$src_file" "-" "$b64_enc" \
    | _filter_out_gpg_otrust_inexistant_keys "$tgt_gnupg_homedir" \
      | _import_gpg_otrust_from_stdin "-" "$tgt_gnupg_homedir" \
        || return 1
}


_print_pipe_expr_deploy_gpg_otrust() {
  # Must print expr equivalent to '_deploy_gpg_otrust' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_gnupg_homedir="${4?}"
  local b64_enc="${5?}"

  _print_pipe_expr_deploy_gpg_file \
    "$prefix" "" "$src_file" "-" "$b64_enc" || return 1
  _print_pipe_expr_filter_out_gpg_otrust_inexistant_keys \
    " | " " | " "$tgt_gnupg_homedir" || return 1
  _print_pipe_expr_import_gpg_otrust_from_stdin \
    "" "$suffix" "-" "$tgt_gnupg_homedir" || return 1
}


_deploy_v_gpg_otrust() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"
  local b64_enc="${3?}"

  _print_pipe_expr_deploy_gpg_otrust \
    "$ " "\n" "$src_file" "$tgt_gnupg_homedir" "$b64_enc" || return 1
  _deploy_gpg_otrust \
    "$src_file" "$tgt_gnupg_homedir" "$b64_enc" || return 1
}


deploy_pgp_gnupg_otrust() {
  local src_file="${1?}"
  local tgt_gnupg_homedir="${2?}"
  local b64_enc="${3:-}"

  # TODO: 'b64_enc' as optiona arg. Use global ass. array to propage.
  # TODO: Support gpp '--gpg-homedir' option arg. Use global array to propagate.

  # We want to test the decryption pipeline beforehand,
  # in order to prevent any corruption of the keyring.
  # This might be longer but is however safer.
  # TODO: Optimize when secure ramfs is available on
  # the target system.
  _deploy_v_gpg_file \
    "$src_file" "/dev/null" "$b64_enc" || return 1
  # Actual keyring import here.
  _deploy_v_gpg_otrust \
    "$src_file" "$tgt_gnupg_homedir" "$b64_enc" || return 1
}
