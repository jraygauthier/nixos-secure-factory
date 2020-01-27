{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  release = import ./release.nix { inherit nixpkgs; };
in

mkShell rec {
  name = "${release.pname}-shell";
  inputsFrom = [
    release
  ];

  buildInputs = [ dieHook ];

  shellHook = ''
    shell_dir="${toString ./.}"
    test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

    export "PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_PACKAGE_ROOT_DIR=$shell_dir"
    . "$shell_dir/env.sh"

    export PKG_NIXOS_SF_FACTORY_COMMON_INSTALL_IN_BUILD_ENV=1
  '';

  passthru.shellHook = shellHook;
}