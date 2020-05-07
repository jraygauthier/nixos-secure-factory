{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  default = (import ./release.nix { inherit pkgs; }).default;
  envLib = import ../../lib/env.nix {
    inherit lib bash-completion;
  };
  env = buildEnv {
    name = "${default.pname}-build-env";
    paths = [ default ];
  };
in

mkShell rec {
  name = "${default.pname}-env";
  buildInputs = [
    env
    dieHook
  ];

  shellHook = ''
    source ${default.envShellHook}

    ${envLib.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
    ${envLib.ensureDynamicBashCompletionLoaderInstalled}

    shell_dir="${toString ./.}"
    test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

    export PKG_NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR="$shell_dir"
    . "$shell_dir/env.sh"

    export PKG_NIXOS_SF_FACTORY_INSTALL_IN_ENV=1
  '';

  passthru.shellHook = shellHook;
}

