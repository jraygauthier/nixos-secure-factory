#!/usr/bin/env bash

common_install_sh_lib_dir="$(pkg-nixos-sf-common-install-get-sh-lib-dir)"
# shellcheck source=prettyprint.sh
. "$common_install_sh_lib_dir/prettyprint.sh"

# TODO: Common implementation shared with system updates.
_run_nix_prefetch_git() {
  local -n _out_cfg_store_path_var_name="$1"
  local -n _out_cfg_src_git_info_json_var_name="$2"
  local channel_url="$3"
  local channel_branch="$4"

  local prefetch_args=( \
    "--url" "$channel_url" \
    "--rev" "$channel_branch" \
    "--no-deepClone" \
  )

  # test -z "$prefetch_out"
  printf "$ nix-prefetch-git %s\n" "$(print_cmd_args "${prefetch_args[@]}")"
  local prefetch_out
  if ! prefetch_out="$(2>&1 nix-prefetch-git "${prefetch_args[@]}")"; then
    1>&2 echo "ERROR: Cannot fetch '$channel_url' repository content. Original error was:"
    1>&2 echo "$prefetch_out"
    return 1
  fi
  echo " -> Ok"

  local out_cfg_store_path
  out_cfg_store_path="$(echo "$prefetch_out" | grep "path is" | awk '{ print $3 }')"
  # echo "out_cfg_store_path='$out_cfg_store_path'"

  local json_begin_ln
  json_begin_ln="$(echo "$prefetch_out" | grep -n -E '^{' | awk -F':' '{ print $1 }')"

  local json_to_eof
  json_to_eof="$(echo "$prefetch_out" | tail -n "+${json_begin_ln}")"

  local json_end_ln
  json_end_ln="$(echo "$json_to_eof" | grep -n -E '^}' | awk -F':' '{ print $1 }')"

  local out_cfg_src_git_info_json
  out_cfg_src_git_info_json="$(echo "$json_to_eof" | head -n "${json_end_ln}")"

  # echo "out_cfg_src_git_info_json='$out_cfg_src_git_info_json'"

  _out_cfg_store_path_var_name="$out_cfg_store_path"
  _out_cfg_src_git_info_json_var_name="$out_cfg_src_git_info_json"
}


_get_yaml_or_json_field_from_file() {
  local filename="${1?}"
  local field_jq_path="${2?}"

  if ! [[ -e "$filename" ]]; then
    1>&2 echo "ERROR: File '$filename' does not not exists."
    return 1
  fi

  local file_bn
  file_bn="$(basename "$filename")"

  local parser_exe="jq"
  local file_type_text="Json"
  if [[ "$file_bn" != "$(basename "$file_bn" yaml)" ]]; then
    # Parse using yq when the file has the yaml extension. Otherwise
    # we will fallback to strict json parser.
    parser_exe="yq"
    file_type_text="Yaml"
  fi

  local out
  if ! out="$(${parser_exe} -e -r "$field_jq_path" < "$filename")"; then
    1>&2 echo "ERROR: ${file_type_text} field '$field_jq_path' not found in file '$filename'."
    return 1
  fi

  echo "$out"
}


_get_optional_yaml_or_json_field_from_file() {
  local filename="${1?}"
  local field_jq_path="${2?}"
  2>/dev/null _get_yaml_or_json_field_from_file "$filename" "$field_jq_path"
}


_get_json_field_from_in_memory_src() {
  local json_str="${1?}"
  local field_jq_path="${2?}"
  local json_str_provenance="${3?}"

  local out
  if ! out="$(echo "$json_str" | jq -e -r "$field_jq_path")"; then
    1>&2 echo "ERROR: Json field '$field_jq_path' not found in '$json_str_provenance'."
    return 1
  fi

  echo "$out"
}


_get_json_field_from_nix_prefetch_git_output() {
  local json_str="${1?}"
  local field_jq_path="${2?}"
  _get_json_field_from_in_memory_src "$json_str" "$field_jq_path" "nix-prefetch-git's output"
}


_update_nix_src_json_using_builtin_fetchgit() {
  local in_src="${1?}"
  local out_src="${2?}"

  local fetcher_type="builtins.fetchGit"

  local url
  url="$(_get_yaml_or_json_field_from_file "$in_src" '.url')" || \
    return 1
  local ref
  ref="$(_get_yaml_or_json_field_from_file "$in_src" '.ref')" || \
    return 1

  # User is allow to specify a fixed rev in which case the mandatory ref
  # is only used as a way to comment the provenance of the specified rev.
  # There is unfortunatly no simple / efficent way to validate the the
  # specified rev belong to the specified ref.
  local fetch_rev
  if ! fetch_rev="$(_get_optional_yaml_or_json_field_from_file "$in_src" '.rev')"; then
    fetch_rev="refs/heads/$ref"
  fi

  local store_path
  local fetch_info_json
  _run_nix_prefetch_git "store_path" "fetch_info_json" "$url" "$fetch_rev"

  # echo "store_path='$store_path'"
  # echo "fetch_info_json='$fetch_info_json'"

  local rev
  rev="$(_get_json_field_from_nix_prefetch_git_output "$fetch_info_json" '.rev')" || \
    return 1
  local sha256
  sha256="$(_get_json_field_from_nix_prefetch_git_output "$fetch_info_json" '.sha256')" || \
    return 1
  local date
  date="$(_get_json_field_from_nix_prefetch_git_output "$fetch_info_json" '.date')" || \
    return 1

  # echo "rev='$rev'"
  # echo "sha256='$sha256'"
  # echo "date='$date'"

  local jq_out_expr
  jq_out_expr='.type = $type | .url = $url | .ref = $ref | .rev = $rev | .sha256 = $sha256 | .date = $date'


  local updated_src_json
  if ! updated_src_json="$(echo "{}" | jq -e \
        --arg type "$fetcher_type" \
        --arg url "$url" \
        --arg ref "$ref" \
        --arg rev "$rev" \
        --arg sha256 "$sha256" \
        --arg date "$date" \
        "$jq_out_expr")"; then
    1>&2 echo "ERROR: Error creating updated source json content."
    return 1
  fi

  if ! echo "$updated_src_json" > "$out_src"; then
    1>&2 echo "ERROR: Error writing updated source to '$out_src'."
    return 1
  fi

  echo "Sources succesfully updated."
  echo "'$out_src' now is:"
  echo "$updated_src_json"
}


_get_json_field_from_nix_prefetch_github_output() {
  local json_str="${1?}"
  local field_jq_path="${2?}"
  _get_json_field_from_in_memory_src "$json_str" "$field_jq_path" "nix-prefetch-github's output"
}


_get_github_rev_from_ref() {
  local owner="${1?}"
  local repo="${2?}"
  local ref="${3?}"
  local url="https://github.com/${owner}/${repo}.git"
  local matching_ls_remote_lns
  if ! matching_ls_remote_lns="$(\
      git ls-remote --symref "$url" \
        | grep -F "refs/heads/${ref}" \
        | grep -E "refs/heads/${ref}$")"; then
    1>&2 echo "ERROR: ${FUNCNAME[0]}: ref '$ref' not found in repository at url '$url'."
    return 1
  fi

  echo "$matching_ls_remote_lns" | awk '{ print $1 }'
}


_update_nix_src_json_using_fetch_from_github() {
  local in_src="${1?}"
  local out_src="${2?}"

  local fetcher_type="fetchFromGitHub"

  local owner
  owner="$(_get_yaml_or_json_field_from_file "$in_src" '.owner')" || \
    return 1
  local repo
  repo="$(_get_yaml_or_json_field_from_file "$in_src" '.repo')" || \
    return 1
  local ref
  ref="$(_get_yaml_or_json_field_from_file "$in_src" '.ref')" || \
    return 1

  # User is allow to specify a fixed rev in which case the mandatory ref
  # is only used as a way to comment the provenance of the specified rev.
  # There is unfortunatly no simple / efficent way to validate the the
  # specified rev belong to the specified ref.
  local fetch_rev
  if ! fetch_rev="$(_get_optional_yaml_or_json_field_from_file "$in_src" '.rev')"; then
    # Workaround for 'seppeljordan/nix-prefetch-github/issues/22' found in V2.3.1.
    # TODO: Remove once fixed.
    fetch_rev="$(_get_github_rev_from_ref "$owner" "$repo" "$ref")"
    # fetch_rev="refs/heads/$ref"
  fi

  # echo "nix-prefetch-github version: $(nix-prefetch-github --version)"

  local prefetch_args=( "--no-prefetch" "--rev" "$fetch_rev" "$owner" "$repo" )
  printf "$ nix-prefetch-github %s\n" "$(print_cmd_args "${prefetch_args[@]}")"

  local prefetch_stdout
  if prefetch_stdout="$(nix-prefetch-github "${prefetch_args[@]}")"; then
    true
  else
    # We print stdout as part of the error message. This is because of
    # 'seppeljordan/nix-prefetch-github/issues/23'.
    local error_code="$?"
    printf "ERROR(%s): nix-prefetch-github failed with stdout: ''\n%s\n''\n" \
      "$error_code" "$prefetch_stdout"
    return 1
  fi

  local rev
  rev="$(_get_json_field_from_nix_prefetch_github_output "$prefetch_stdout" '.rev')" || \
    return 1
  local sha256
  sha256="$(_get_json_field_from_nix_prefetch_github_output "$prefetch_stdout" '.sha256')" || \
    return 1

  # echo "rev='$rev'"
  # echo "sha256='$sha256'"

  local jq_out_expr
  jq_out_expr='.type = $type | .owner = $owner | .repo = $repo | .ref = $ref | .rev = $rev | .sha256 = $sha256'

  local updated_src_json
  if ! updated_src_json="$(echo "{}" | jq -e \
        --arg type "$fetcher_type" \
        --arg owner "$owner" \
        --arg repo "$repo" \
        --arg ref "$ref" \
        --arg rev "$rev" \
        --arg sha256 "$sha256" \
        "$jq_out_expr")"; then
    1>&2 echo "ERROR: Error creating updated source json content."
    return 1
  fi

  if ! echo "$updated_src_json" > "$out_src"; then
    1>&2 echo "ERROR: Error writing updated source to '$out_src'."
    return 1
  fi

  echo "Sources succesfully updated."
  echo "'$out_src' now is:"
  echo "$updated_src_json"
}


update_nix_src_json() {
  local in_src="${1?}"
  local out_src="${2?}"

  local fetcher_type
  fetcher_type="$(_get_yaml_or_json_field_from_file "$in_src" '.type')" \
    || return 1

  # echo "fetcher_type='$fetcher_type'"

  if [[ "$fetcher_type" == "builtins.fetchGit" ]]; then
    _update_nix_src_json_using_builtin_fetchgit "$in_src" "$out_src"
  elif [[ "$fetcher_type" == "fetchFromGitHub" ]]; then
    _update_nix_src_json_using_fetch_from_github "$in_src" "$out_src"
  else
    1>&2 echo "ERROR: Unsupported fetcher type '$fetcher_type'."
    return 1
  fi
}


update_nix_src_json_cli() {
  local in_src="${1?}"
  local out_src="${2?}"

  print_title_lvl3 "Updating nix src from '$in_src' to '$out_src'"

  update_nix_src_json "$in_src" "$out_src"
}
