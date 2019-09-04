#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/prompt.sh"
. "$common_factory_install_libexec_dir/gopass.sh"
. "$common_factory_install_libexec_dir/app_factory_info_store.sh"


get_gopass_device_vault_id() {
  local out_id
  out_id="$(get_required_factory_info__gopass_default_device_vault_id)"
  echo "$out_id"
}


get_gopass_factory_only_vault_id() {
  local out_id
  out_id="$(get_required_factory_info__gopass_factory_only_vault_id)"
  echo "$out_id"
}


get_gopass_device_vault_repo_dir() {
  local repo_name
  repo_name="$(get_required_factory_info__gopass_default_device_vault_repo_name)"

  local top_lvl
  top_lvl="$(get_factory_install_repo_parent_dir)"
  echo "$top_lvl/$repo_name"
}


get_gopass_factory_only_vault_repo_dir() {
  local repo_name
  repo_name="$(get_required_factory_info__gopass_factory_only_vault_repo_name)"

  local top_lvl
  top_lvl="$(get_factory_install_repo_parent_dir)"
  echo "$top_lvl/$repo_name"
}


is_factory_gopass_main_store_initialized() {
  local gpg_key_id
  read_or_prompt_for_factory_info__user_gpg_default_id "gpg_key_id"

  test -e "$HOME/.password-store" \
    && gopass --yes mounts | head -n 1 | grep -q "$HOME/.password-store" \
    && gopass recipients | tail -n 2 | grep -q "$gpg_key_id"
}


list_gopass_main_store_and_config_files() {
  local files
  files="$(
    test -d "$HOME/.config/gopass" \
      && find "$HOME/.config/gopass" -mindepth 1 -type f
    find "$HOME/.config" -mindepth 1 -maxdepth 1 -type d -name gopass
    find "$HOME" -mindepth 1 -maxdepth 1 -type d -name '.password-store*'
  )"
  printf "$files" | grep ^
}


rm_factory_gopass_main_store_and_config() {
  print_title_lvl4 "Removing factory gopass main store and config"

  local to_be_rm_files
  if ! to_be_rm_files="$(list_gopass_main_store_and_config_files)"; then
    echo "Nothing to remove."
    return 0
  fi

  echo "The following files will be removed:"
  echo "$to_be_rm_files" | awk '{ print "  " $0 }'
  prompt_for_user_approval || return 1

  echo "Removing the files."
  echo "$to_be_rm_files" | xargs -r rm -r --
}


init_factory_gopass_main_store_and_config() {
  print_title_lvl4 "Initializing factory gopass main store and config"

  if is_factory_gopass_main_store_initialized; then
    echo "Factory gopass main store already initialized."
    return 0
  fi

  local gpg_key_id
  read_or_prompt_for_factory_info__user_gpg_default_id "gpg_key_id"

  echo_eval "gopass --yes init '$gpg_key_id'"
}


configure_factory_gopass_secrets_stores() {
  stores_ids="$(
    get_gopass_factory_only_vault_id
    get_gopass_device_vault_id
  )"

  for sid in $stores_ids; do
    configure_gopass_store "$sid"
  done
}


mount_factory_gopass_secrets_stores() {
  print_title_lvl4 "Mounting factory gopass secret stores"

  init_factory_gopass_main_store_and_config

  local gpg_key_id
  read_or_prompt_for_factory_info__user_gpg_default_id "gpg_key_id"
  local top_lvl
  top_lvl="$(get_factory_install_repo_parent_dir)"

  # TODO: In case already mounted, validate that it points to expected repo.
  # TODO: Retrieve from factory config state.
  echo_eval "gopass mounts add -i '$gpg_key_id'" \
    "'$(get_gopass_factory_only_vault_id)'" \
    "'$(get_gopass_factory_only_vault_repo_dir)'"
  echo_eval "gopass mounts add -i '$gpg_key_id'" \
    "'$(get_gopass_device_vault_id)'" \
    "'$(get_gopass_device_vault_repo_dir)'"

  configure_factory_gopass_secrets_stores
}


umount_factory_gopass_secrets_stores() {
  print_title_lvl4 "Unmounting factory gopass secret stores"

  init_factory_gopass_main_store_and_config

  echo_eval "gopass mounts remove '$(get_gopass_factory_only_vault_id)'"
  echo_eval "gopass mounts remove '$(get_gopass_device_vault_id)'"
}
