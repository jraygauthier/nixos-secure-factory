#!/usr/bin/env bash
common_factory_install_libexec_dir="$(pkg-nixos-factory-common-install-get-libexec-dir)"
. "$common_factory_install_libexec_dir/tools.sh"



misc() {
  GOPASS_CONFIG="$PWD/gopass.yaml" GOPASS_HOMEDIR="$PWD" gopass init --path "$PWD/my_store5" myuser@mydomain.com
}


configure_gopass_store() {
  local store_id="$1"
  gopass config --store "$store_id" autosync false
  gopass config --store "$store_id" autoimport true

  # TODO: Consider this.
  gopass config --store "$store_id" check_recipient_hash false

  gopass config --store "$store_id" noconfirm true
  gopass config --store "$store_id" nopager true
  # gopass config --store "$store_id" nocolor true

  gopass config --store "$store_id" askformore false
  gopass config --store "$store_id" notifications false
  gopass config --store "$store_id" safecontent false
}


configure_gopass_root_store() {
  store_id=""
  gopass config --store "$store_id" autosync false
  gopass config --store "$store_id" autoimport true

}
