#!/usr/bin/env bash

data_deploy_sh_lib_dir="$(pkg-nsf-data-deploy-tools-get-sh-lib-dir)"
# shellcheck source=deploy-tools.sh
. "$data_deploy_sh_lib_dir/deploy-tools.sh"


_exit_with_error_printf() {
  local error_code"${1?}"
  local msg_printf_format="${2?}"
  shift 2

  local exe_name
  exe_name="$(basename "$0")"

  local caller_fn_name="${FUNCNAME[1]}"

  local user_error_str
  # shellcheck disable=SC2059
  printf -v user_error_str "$msg_printf_format" "$@"

  1>&2 printf \
    "ERROR: %s: %s: %s" \
    "$exe_name" "$caller_fn_name" "$user_error_str"

  # shellcheck disable=SC2154
  exit "$error_code"
}


_warn_printf() {
  local msg_printf_format="${1?}"
  shift 1

  local exe_name
  exe_name="$(basename "$0")"

  local caller_fn_name="${FUNCNAME[1]}"

  local user_error_str
  # shellcheck disable=SC2059
  printf -v user_error_str "$msg_printf_format" "$@"

  1>&2 printf \
    "WARNING: %s: %s: %s" \
    "$exe_name" "$caller_fn_name" "$user_error_str"
}


_print_file_extensions() {
  local file="${1?}"
  echo "$file" | tr '/' '\n' | tail -n -1 | cut -s -d. -f2-
}


_print_last_file_extension_from_exts() {
  local file_exts="${1?}"
  echo "$file_exts" | awk -F. 'NF < 1 { exit 1 } { print $NF }'
}


_print_2nd_last_file_extension_from_exts() {
  local file_exts="${1?}"
  echo "$file_exts" | awk -F. 'NF < 2 { exit 1 } { print $(NF - 1) }'
}


_check_has_gpg_extension_from_exts() {
  local file_exts="${1?}"

  local gnu_ext
  if gnu_ext="$(_print_last_file_extension_from_exts "$file_exts")" \
      && [[ "gpg" == "$gnu_ext" ]] ; then
    true
  else
    _exit_with_error_printf 1 "unexpected last extension '%s'.\n -> Expected 'gpg'.\n" \
      "$gnu_ext"
  fi
}


_ensure_supported_gpg_enc_exts() {
  local src_file="${1?}"
  local b64_enc="${2?}"

  local file_exts
  file_exts="$(_print_file_extensions "$src_file")" || return 1

  if ! _is_b64_encoding_explicit "$b64_enc"; then
    _check_has_gpg_extension_from_exts "$file_exts" || return 1
  fi

  echo "$file_exts"
}

# TODO: Use this instead of deploying to /dev/null.
#       Should prevent unrequired timestamps modifications.
_compute_sha256_sum() {
  local src_file="${1?}"
  sha256sum "$src_file" | cut -d' ' -f1
}


_print_pipe_expr_compute_sha256_sum() {
  # Must print expr equivalent to 'compute_sha256_sum' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  printf "%b" "$prefix"
  printf "sha256sum %q | cut -d' ' -f1" "$src_file"
  printf "%b" "$suffix"
}


_print_pipe_expr_gpg() {
  local prefix="${1?}"
  local suffix="${2?}"
  shift 2
  local gpg_args=( "$@" )
  printf "%b" "$prefix"
  local gpg_pl_str
  gpg_pl_str="$(printf "%q\n" "gpg" "${gpg_args[@]}" | paste -s -d' ')" || return 1
  printf "%s%b" "$gpg_pl_str" "$suffix"
}


_build_gpg_home_dir_argsa() {
  # shellcheck disable=SC2178
  local -n _out_gpg_home_dir_arg_a="${1?}"
  local tgt_gnupg_homedir="${2?}"

  _out_gpg_home_dir_arg_a=()

  if [[ "1" == "${tgt_gnupg_homedir:+1}" ]]; then
    # shellcheck disable=SC2034
    _out_gpg_home_dir_arg_a=( \
      --homedir "$tgt_gnupg_homedir" \
    )
  fi
}


_build_gpg_decrypt_argsa() {
  local -n _out_gpg_arg_a="${1?}"
  local src_file="${2?}"
  local tgt_file="${3?}"
  # shellcheck disable=SC2034
  _out_gpg_arg_a=( \
    --batch --pinentry-mode loopback \
    --yes --quiet \
    --decrypt \
    --output "$tgt_file" \
    "$src_file" )
}


_deploy_gpg_plain_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  local gpg_args
  _build_gpg_decrypt_argsa "gpg_args" "$src_file" "$tgt_file" || return 1
  gpg "${gpg_args[@]}" || return 1
}


_print_pipe_expr_deploy_gpg_plain_file() {
  # Must print expr equivalent to '_deploy_gpg_plain_file' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_file="${4?}"

  local gpg_args
  _build_gpg_decrypt_argsa "gpg_args" "$src_file" "$tgt_file" || return 1
  _print_pipe_expr_gpg "$prefix" "$suffix" "${gpg_args[@]}"
}


_is_b64_encoding_explicit() {
  local b64_encoded="${1?}"
  if [[ "1" == "$b64_encoded" ]]; then
    true
  elif [[ "0" == "$b64_encoded" ]]; then
    true
  else
    false
  fi
}


_should_assume_pgp_b64_encoded() {
  local file_exts="${1?}"
  local b64_encoded="${2:-}"

  local opt_b64_ext
  if [[ "1" == "$b64_encoded" ]]; then
    true
  elif [[ "0" == "$b64_encoded" ]]; then
    false
  elif [[ "" == "$b64_encoded" ]]; then
    if opt_b64_ext="$(_print_2nd_last_file_extension_from_exts "$file_exts")" \
        && [[ "b64" == "$opt_b64_ext" ]]; then
      true
    else
      false
    fi
  else
    _exit_with_error_printf 1 "unexpected 'b64_encoded' argument value: '%s'.\n -> Expected '1', '0' or ''.\n" \
      "$b64_encoded"
  fi
}


_deploy_base64_encoded_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  if [[ "-" == "$tgt_file" ]]; then
    base64 -d "$src_file"
  else
    base64 -d "$src_file" > "$tgt_file"
  fi
}


_print_pipe_expr_deploy_base64_encoded_file() {
  # Must print expr equivalent to '_deploy_base64_encoded_file' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_file="${4?}"
  printf "%b" "$prefix"
  printf "base64 -d %q" "$src_file"
  if [[ "-" != "$tgt_file" ]]; then
    printf " > %q" "$tgt_file"
  fi
  printf "%b" "$suffix"
}


_deploy_gpg_base64_encoded_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  _deploy_gpg_plain_file "$src_file" "-" | _deploy_base64_encoded_file "-" "$tgt_file" || return 1
}


_print_pipe_expr_deploy_gpg_base64_encoded_file() {
  # Must print expr equivalent to '_deploy_gpg_base64_encoded_file' above.
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_file="${4?}"

  _print_pipe_expr_deploy_gpg_plain_file \
    "$prefix" "" "$src_file" "-" || return 1
  _print_pipe_expr_deploy_base64_encoded_file \
    " | " "$suffix" "-" "$tgt_file" || return 1
}


_deploy_gpg_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  local b64_enc="${3?}"

  local file_exts
  file_exts="$(_ensure_supported_gpg_enc_exts \
    "$src_file" "$b64_enc")" || return 1

  if _should_assume_pgp_b64_encoded "$file_exts" "$b64_enc"; then
    # Has been base64 encoded before encryption.
    _deploy_gpg_base64_encoded_file "$src_file" "$tgt_file" || return 1
  else
    # Has not been base64 encoded. Only decrypt.
    _deploy_gpg_plain_file "$src_file" "$tgt_file" || return 1
  fi
}


_print_pipe_expr_deploy_gpg_file() {
  local prefix="${1?}"
  local suffix="${2?}"
  local src_file="${3?}"
  local tgt_file="${4?}"
  local b64_enc="${5?}"

  local file_exts
  file_exts="$(_ensure_supported_gpg_enc_exts \
    "$src_file" "$b64_enc")" || return 1

  if _should_assume_pgp_b64_encoded "$file_exts" "$b64_enc"; then
    _print_pipe_expr_deploy_gpg_base64_encoded_file \
      "$prefix" "$suffix" "$src_file" "$tgt_file" || return 1
  else
    _print_pipe_expr_deploy_gpg_plain_file \
      "$prefix" "$suffix" "$src_file" "$tgt_file" || return 1
  fi
}


_deploy_v_gpg_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  local b64_enc="${3?}"

  _print_pipe_expr_deploy_gpg_file \
    "$ " "\n" "$src_file" "$tgt_file" "$b64_enc" || return 1
  _deploy_gpg_file \
    "$src_file" "$tgt_file" "$b64_enc" || return 1
}


decrypt_pgp_file_to_stdout() {
  local src_file="${1?}"
  local b64_enc="${2:-}"
  _deploy_gpg_file \
    "$src_file" "-" "$b64_enc"
}


deploy_pgp_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  local b64_enc="${3:-}"

  # TODO: 'b64_enc' as optiona arg. Use global ass. array to propage.
  # TODO: Support gpp '--gpg-homedir' option arg. Use global array to propagate.

  # We want to rule out any gpg issues before writing the file.
  # TODO: Optimize when secure ramfs is available on
  # the target system.
  _deploy_v_gpg_file "$src_file" "/dev/null" "$b64_enc" || return 1
  # We do the actual job here.
  _deploy_v_gpg_file "$src_file" "$tgt_file" "$b64_enc" || return 1
}


deploy_pgp_file_w_inherited_permissions() {
  local src_file="${1?}"
  local tgt_file="${2?}"
  local b64_enc="${3:-}"

  # TODO: 'b64_enc' as optiona arg. Use global ass. array to propage.
  # TODO: Support gpp '--gpg-homedir' option arg. Use global array to propagate.

  local tgt_dir
  tgt_dir="$(dirname "$tgt_file")" || return 1
  mkdir_w_inherited_permissions "$tgt_dir" || return 1
  deploy_pgp_file "$src_file" "$tgt_file" "$b64_enc" || return 1
  inherit_permissions_from "$tgt_file" "$tgt_dir" || return 1
}
