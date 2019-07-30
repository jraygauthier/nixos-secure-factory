#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg_nixos_factory_common_install_get_libexec_dir)"
. "$common_factory_install_libexec_dir/tools.sh"
. "$common_factory_install_libexec_dir/vcs.sh"


sync_repositories() {
  local repo_urls="$1"

  # TODO: Consider using something like google repo or mr.
  local top_lvl
  top_lvl="$(get_factory_install_repo_parent_dir)"

  print_title_lvl1 "Synching this project's dependencies"


  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl2 "Repo: '$repo_name'"

    if test -d "$repo_dir"; then
      echo "Synching '$repo_dir' via \`pull\` from origin."
      git -C "$repo_dir" pull || true
    else
      echo "Synching '$repo_dir' via \`clone\` from '$repo_url'."
      git -C "$top_lvl" clone "$repo_url"
    fi

    print_title_lvl3 "Repo status"
    # git -C "$repo_dir" -c color.status=always status
    git -C "$repo_dir" status

    printf -- "\n\n"

  done
}


init_mr_config_for_repositories() {
  local repo_urls="$1"

  # TODO: Consider using something like google repo or mr.
  local top_lvl
  top_lvl="$(get_factory_install_repo_parent_dir)"

  print_title_lvl1 "Creating mr config for this project's dependencies"

  rm -f "$top_lvl/.mrconfig"
  touch "$top_lvl/.mrconfig"
  touch "$HOME/.mrtrust"
  echo "$top_lvl/.mrconfig" >> "$HOME/.mrtrust"

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    echo "Repo: '$repo_name'"

    mr config "$repo_name" checkout="$repo_url"
  done
}
