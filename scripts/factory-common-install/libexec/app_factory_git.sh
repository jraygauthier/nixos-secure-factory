#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-sf-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/prompt.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"
. "$common_factory_install_libexec_dir/git.sh"


_configure_git_minimally_impl() {
  local suggested_user_email=""
  suggested_user_email="$(get_required_factory_info__user_email 2>/dev/null)" \
    || true

  local suggested_user_name=""
  suggested_user_name="$(get_required_factory_info__user_full_name 2>/dev/null)" \
    || true

  local treat_missing_fields_as_error=false
  ensure_minimal_git_config_prompt_and_setup_if_not \
    "$suggested_user_email" "$suggested_user_name" \
    "$treat_missing_fields_as_error"
}


configure_git_minimally() {
  echo "Checking for git minimal configuration fields."
  _configure_git_minimally_impl
  echo "Ok, user's git configuration meets minimal requirements."
}


configure_git_minimally_cli() {
  print_title_lvl1 "Configuring user's git so that it meets minimal requirements"

  echo "Checking for git minimal configuration fields."

  if has_minimal_git_config; then
    echo "User's git configuration already meets minimal requirements."
    if ! prompt_for_user_approval "Do you want to change it"; then
      return 0
    fi

    change_minimal_git_config
    echo "Ok, user's git configuration successfully changed."
    return $?
  fi

  _configure_git_minimally_impl
  echo "Ok, user's git configuration meets minimal requirements."
}
