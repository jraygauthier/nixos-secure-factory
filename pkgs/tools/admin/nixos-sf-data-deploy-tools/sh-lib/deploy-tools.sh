#!/usr/bin/env bash

change_mode() {
  local tgt_file="${1?}"
  local new_mode="${2?}"
  local chmod_args=( "$new_mode" "$tgt_file" )
  echo chmod "${chmod_args[@]}"
  chmod "${chmod_args[@]}"
}


change_owner() {
  local tgt_file="${1?}"
  local owner="${2:-}"
  local group="${3:-}"

  local chown_args=( "${owner}${group:+":"}${group}" "$tgt_file" )
  echo chown "${chown_args[@]}"
  chown "${chown_args[@]}"
}


inherit_mode_from() {
  local tgt_file="${1?}"
  local from_file="${2?}"

  local chmod_args=( --reference "$from_file" "$tgt_file" )
  echo chmod "${chmod_args[@]}"
  chmod "${chmod_args[@]}"
}


inherit_owner_from() {
  local tgt_file="${1?}"
  local from_file="${2?}"

  local chown_args=( --reference "$from_file" "$tgt_file" )
  echo chown "${chown_args[@]}"
  chown "${chown_args[@]}"
}


inherit_permissions_from() {
  local tgt_file="${1?}"
  local from_file="${2?}"

  inherit_mode_from "$tgt_file" "$from_file"
  inherit_owner_from "$tgt_file" "$from_file"
}


mkdir_w_inherited_permissions() {
  local in_dir="${1?}"

  local to_be_created=()
  if ! [[ -d "$in_dir" ]]; then
    to_be_created=( "$in_dir" "${to_be_created[@]}" )
  fi

  local p_dir
  p_dir="$(dirname "$in_dir")"

  while [[ "${#p_dir}" -gt 1 ]] \
      && ! [[ -d "$p_dir" ]]; do
    to_be_created=( "$p_dir" "${to_be_created[@]}" )
    p_dir="$(dirname "$p_dir")"
  done

  if ! [[ -d "$p_dir" ]]; then
    1>&2 echo "ERROR: find_first_existing_parent_dir: No parent dir for '$in_dir'."
    return 1
  fi

  local oct_mode
  oct_mode="$(stat -c '%a' "$p_dir")"

  for d in "${to_be_created[@]}"; do
    local mkdir_args=( -m "$oct_mode" "$d" )
    echo mkdir "${mkdir_args[@]}"
    mkdir "${mkdir_args[@]}"
    inherit_permissions_from "$d" "$p_dir"
  done
}


deploy_file() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  local cp_args=( "$src_file" "$tgt_file" )
  echo cp "${cp_args[@]}"
  cp "${cp_args[@]}"
}


deploy_file_w_inherited_permissions() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  local tgt_tmp_dir
  tgt_tmp_dir="$(dirname "$tgt_file")"
  mkdir_w_inherited_permissions "$tgt_tmp_dir"
  deploy_file "$src_file" "$tgt_file"
  inherit_permissions_from "$tgt_file" "$tgt_tmp_dir"
}


rm_file() {
  local in_file="${1?}"
  local rm_args=( "-f" "$in_file" )
  echo rm "${rm_args[@]}"
  rm "${rm_args[@]}"
}
