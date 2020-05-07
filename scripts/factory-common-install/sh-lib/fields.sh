#!/usr/bin/env bash
# common_factory_install_sh_lib_dir="$(pkg-nixos-sf-factory-common-install-get-sh-lib-dir)"



_LATIN_ACCENTED_CHARS="àäçéèëïìÀÄÇÉÈËÏÌ"


get_latin_accented_chars() {
  echo "$_LATIN_ACCENTED_CHARS"
}


get_user_full_name_regexpr() {
  # local _value_re="^[a-zA-Z0-9\u00C0-\u00D6\u00D8-\u00f6\u00f8-\u00ff\s_]+$"
  # TODO: Review this if at some point non latin alphabets are required.
  echo "^[a-zA-Z0-9$(get_latin_accented_chars)_ -]+$"
}


get_email_address_regexpr() {
  echo "^[a-zA-Z0-9@\.$(get_latin_accented_chars)_-]+$"
}


get_email_domain_regexpr() {
  echo "^[a-zA-Z0-9\.$(get_latin_accented_chars)_-]+$"
}

get_file_basename_regexpr() {
  echo "^[a-zA-Z0-9\._-]+$"
}

get_gpg_id_or_email_regexpr() {
  get_email_address_regexpr
}
