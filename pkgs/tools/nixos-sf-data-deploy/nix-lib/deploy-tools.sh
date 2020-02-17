#!/usr/bin/env bash

mkdir_w_inherited_access() {
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
  local uid
  uid="$(stat -c '%u' "$p_dir")"
  local gid
  gid="$(stat -c '%g' "$p_dir")"

  for d in "${to_be_created[@]}"; do
    local mkdir_args=( -m "$oct_mode" "$d" )
    echo mkdir "${mkdir_args[@]}"
    mkdir "${mkdir_args[@]}"
    local chown_args=( "${uid}:${gid}" "$d" )
    echo chown "${chown_args[@]}"
    chown "${chown_args[@]}"
  done
}


deploy_file_w_inherited_access() {
  local src_file="${1?}"
  local tgt_file="${2?}"

  local tgt_dir
  tgt_dir="$(dirname "$tgt_file")"
  mkdir_w_inherited_access "$tgt_dir"

  local oct_mode
  oct_mode="$(stat -c '%a' "$tgt_dir")"
  local uid
  uid="$(stat -c '%u' "$tgt_dir")"
  local gid
  gid="$(stat -c '%g' "$tgt_dir")"

  local cp_args=( "$src_file" "$tgt_file" )
  echo cp "${cp_args[@]}"
  cp "${cp_args[@]}"

  local chmod_args=( "$oct_mode" "$tgt_file" )
  echo chmod "${chmod_args[@]}"
  chmod "${chmod_args[@]}"

  local chown_args=( "${uid}:${gid}" "$tgt_file" )
  echo chown "${chown_args[@]}"
  chown "${chown_args[@]}"
}


change_mode() {
  local tgt_file="${1?}"
  local new_mode="${2?}"
  local chmod_args=( "$new_mode" "$tgt_file" )
  echo chmod "${chmod_args[@]}"
  chmod "${chmod_args[@]}"
}


change_owner() {
  local tgt_file="${1?}"
  local new_owner="${2:-}"
  local new_owner_group="${3:-}"

  previous_uid="$(stat -c '%u' "$tgt_file")"
  local owner="${new_owner:-"$previous_uid"}"

  previous_gid="$(stat -c '%g' "$tgt_file")"
  local group="${new_owner_group:-"$previous_gid"}"

  local chown_args=( "${owner}:${group}" "$tgt_file" )
  echo chown "${chown_args[@]}"
  chown "${chown_args[@]}"
}


rm_file() {
  local in_file="${1?}"
  local rm_args=( "-f" "$in_file" )
  echo rm "${rm_args[@]}"
  rm "${rm_args[@]}"
}
