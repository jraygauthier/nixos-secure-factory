#!/usr/bin/env bash
common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"
# shellcheck source=SCRIPTDIR/../sh-lib/tools.sh
. "$common_factory_install_sh_lib_dir/tools.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/vcs.sh
. "$common_factory_install_sh_lib_dir/vcs.sh"
# shellcheck source=SCRIPTDIR/../sh-lib/workspace_paths.sh
. "$common_factory_install_sh_lib_dir/workspace_paths.sh"

update_repositories() {
  local repo_urls="$1"
  local branch_name="${2:-}"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Updating a set of repositories"

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"

    if test -d "$repo_dir"; then
      if [[ -n "$branch_name" ]]; then
        echo "Checkout '$repo_dir' to branch '$branch_name'."
        echo_eval "git -C '$repo_dir' checkout '$branch_name'"
      fi
      echo "Updating '$repo_dir' via \`pull -r\` from origin."
      echo_eval "git -C '$repo_dir' pull -r --autostash"
    else
      local cloned_branch_name="${branch_name:-master}"
      echo "Updating '$repo_dir' via \`clone\` from '$repo_url' at branch '$cloned_branch_name'."
      echo_eval "git -C '$top_lvl' clone --branch '$cloned_branch_name' '$repo_url'"
    fi

    printf -- "\n\n"

  done
}


update_repositories_remotes() {
  local repo_urls="$1"
  local branch_name="${2:-}"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Updating a set of repositories're remotes"

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"

    if test -d "$repo_dir"; then
      echo "Updating '$repo_dir''s remote to '$repo_url'."
      echo_eval "git -C '$repo_dir' remote set-url origin '$repo_url'"
      # TODO: Update push to also when set? Do we ask?
    else
      1>&2 echo "ERROR: Repository does not exists at '$repo_dir'. Please clone it."
    fi

    printf -- "\n\n"

  done
}


checkout_repositories_w_stash() {
  local repo_urls="$1"
  local branch_name="$2"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Checkouting a branch for a set of repositories moving uncommitted changes to target branch"

  # TODO: How to restore global integrity in case of a error in stash pop?

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"
    echo "Checkout '$repo_dir''s branch '$branch_name'."
    echo_eval "git -C '$repo_dir' stash && git -C '$repo_dir' checkout '$branch_name' && git -C '$repo_dir' stash pop"

    printf -- "\n\n"
  done
}


checkout_repositories() {
  local repo_urls="$1"
  local branch_name="$2"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Checkouting a branch for a set of repositories"

  # TODO: In case of an error, checkout back to the previous branch.

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"
    echo "Checkout '$repo_dir''s branch '$branch_name'."
    echo_eval "git -C '$repo_dir' checkout '$branch_name'"

    printf -- "\n\n"
  done
}


print_repositories_status() {
  local repo_urls="$1"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Printing the status of a set of repositories"

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"

    echo_eval "git -C '$repo_dir' status"

    printf -- "\n\n"

  done
}


push_repositories() {
  local repo_urls="$1"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Synching a set of repositories"

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"

    echo "Pushing '$repo_dir' to tracked remote."
    echo_eval "git -C '$repo_dir' push"

    printf -- "\n\n"

  done
}


sync_repositories() {
  local repo_urls="$1"
  local branch_name="${2:-}"
  update_repositories "$repo_urls" "$branch_name" && \
  push_repositories "$repo_urls"
}


add_and_commit_repositories() {
  local repo_urls="$1"
  local commit_msg="${2:-No comments}"

  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Adding changes and committing to a set of repositories"

  for repo_url in $repo_urls; do
    local repo_name
    repo_name="$(basename "$repo_url" ".git")"
    local repo_dir="$top_lvl/$repo_name"

    print_title_lvl3 "Repo: '$repo_name'"

    echo_eval "git -C '$repo_dir' add ."
    if ! git -C "$repo_dir" diff --cached --exit-code > /dev/null; then
      # Not an error when nothing to commit
      echo_eval "git -C '$repo_dir' commit -m '$commit_msg'"
    fi

    printf -- "\n\n"

  done
}


add_commit_and_sync_repositories() {
  local repo_urls="$1"
  local commit_msg="${2:-No comments}"

  add_and_commit_repositories "$repo_urls" "$commit_msg"
  sync_repositories "$repo_urls"
}


init_mr_config_for_repositories() {
  local repo_urls="$1"

  # TODO: Consider using something like google repo or mr.
  local top_lvl
  top_lvl="$(get_nixos_secure_factory_workspace_dir)"

  print_title_lvl2 "Creating mr config for this project's dependencies"

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
