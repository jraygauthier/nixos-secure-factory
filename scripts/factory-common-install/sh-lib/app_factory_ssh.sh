#!/usr/bin/env bash

list_ssh_prefered_host_key_algos() {
  # List ssh supported host key algos in the order of
  # preference.
  # Remove all openssh specific variants.
  # Remove the 'ssh-' prefix.
  ssh -Q key | grep -v -E '@openssh.com$' | sed -r -e 's/^ssh-(.+)$/\1/'
}


# Will return 'list_ssh_prefered_host_key_algos' elements
# which are part of the set of algorithms passed as argument.
list_ssh_prefered_host_key_algos_in_set() {
  declare -a other_algo_array=( "$@" )

  local algo_list
  algo_list="$(list_ssh_prefered_host_key_algos)"

  local r_code=1

  for a in $algo_list; do
    if printf "%s\n" "${other_algo_array[@]}" | grep -x "$a"; then
      r_code=0
    fi
  done

  return "$r_code"
}
