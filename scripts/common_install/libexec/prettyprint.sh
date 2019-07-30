#!/usr/bin/env bash
# common_install_libexec_dir="$(pkg_nixos_common_install_get_libexec_dir)"



_get_title_lenght() {
  title="$1"
  printf "%s" "$title" | wc -m
}


_print_title_char_under() {
  title="$1"
  char_under="$2"
  printf -- "\n"
  printf -- "%s\n" "${title}"

  for _ in $(seq 1 "$(_get_title_lenght "$title")"); do
    printf -- "%s" "$char_under"
  done
  printf -- "\n\n"
}


print_title_lvl1() {
  _print_title_char_under "$1" "="
}


print_title_lvl2() {
  _print_title_char_under "$1" "-"
}


_print_title_chars_each_side() {
  title="$1"
  chars_each_side="$2"
  printf -- "\n"
  printf -- "%s %s %s\n" "${chars_each_side}" "${title}" "${chars_each_side}"
  printf -- "\n"
}


print_title_lvl3() {
  _print_title_chars_each_side "$1" "###"
}


print_title_lvl4() {
  _print_title_chars_each_side "$1" "####"
}

print_title_lvl5() {
  _print_title_chars_each_side "$1" "#####"
}

print_title_lvlx() {
  title="$1"
  title_lvl="$2"

  if LC_ALL=C type "print_title_lvl${title_lvl}" &> /dev/null; then
    eval "print_title_lvl${title_lvl}" "$title"
  else
    2>&1 echo "WARNING: print_title_lvlx: Undefined title level: '$title_lvl'. Fallback to echo."
    echo "$title"
  fi
}


echo_eval() {
  echo "\$" "$@"
  eval "$@"
}

eval_only() {
  eval "$@"
}
