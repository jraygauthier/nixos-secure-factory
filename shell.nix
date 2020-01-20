{ nixpkgs ? import <nixpkgs> {} }:

let
  nixos-sf-factory-install = import scripts/factory-install/env.nix {};
in

nixpkgs.mkShell rec {

  inputsFrom = [ ];

  buildInputs = [
    nixos-sf-factory-install
  ];

  shellHook = ''
    shell_dir="$(pwd)"
    workspace_root_dir="$(cd "$shell_dir" && pwd)"

    factory_install_dir="$shell_dir/scripts/factory-install"
    if ! [[ -d "$factory_install_dir" ]]; then
      1>&2 echo "ERROR: Cannot find factory install dir at: '$factory_install_dir'."
      exit 1
    fi

    NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR="$factory_install_dir"
    . "$factory_install_dir/env.sh"
    unset NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR

    export PKG_NIXOS_SF_FACTORY_INSTALL_IN_ENV=1
  '';

  passthru.shellHook = shellHook;
}
