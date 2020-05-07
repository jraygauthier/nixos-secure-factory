{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  default = (import ./release.nix { inherit pkgs; }).default;
in

mkShell rec {
  name = "${default.pname}-shell";
  inputsFrom = [
    default
  ];

  buildInputs = [ dieHook ];

  shellHook = ''
    shell_dir="${toString ./.}"
    test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

    export "PKG_NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR=$shell_dir"
    . "$shell_dir/env.sh"

    export PKG_NIXOS_SF_FACTORY_INSTALL_IN_BUILD_ENV=1
  '';

  passthru.shellHook = shellHook;
}
