#!/usr/bin/env bash

# Meant to be sourced.
# Depends on 'CURRENT_PACKAGE_ROOT_DIR' being set to this script's dir.

CURRENT_REPOSITORY_SCRIPTS_DIR="$(cd "$CURRENT_PACKAGE_ROOT_DIR/.." > /dev/null && pwd)"
! test -e "$CURRENT_REPOSITORY_SCRIPTS_DIR/.local-env.sh" || \
  . "$CURRENT_REPOSITORY_SCRIPTS_DIR/.local-env.sh"
unset CURRENT_REPOSITORY_SCRIPTS_DIR
