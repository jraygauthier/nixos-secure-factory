#!/usr/bin/env bash

create_and_assign_proper_permissions_to_dir_lazy() {
  local target_dir="$1"
  local octal_mode="$2"

  if test -d "$target_dir"; then
    if test "$octal_mode" != "$(stat -c '%a' "$target_dir")"; then
      chmod "$octal_mode" "$target_dir"
    fi
  else
    mkdir -m "$octal_mode" -p "$target_dir"
  fi
}

