#!/usr/bin/env bash

is_mem_sh_stream_empty() {
  local in_stream="$1"
  local stream_element_count="$(printf "%s\n" "$in_stream" | wc -l)"
  [[ -z "$in_stream" ]] || [[ "0" -eq "$stream_element_count" ]]
}


is_mem_sh_stream_singleton() {
  local in_stream="$1"
  local stream_element_count="$(printf "%s\n" "$in_stream" | wc -l)"
  [[ "1" -eq "$stream_element_count" ]]
}
