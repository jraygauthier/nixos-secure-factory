{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  release = import ./release.nix { inherit nixpkgs; };
  envLib = import ../../lib/env.nix {
    inherit lib bash-completion;
  };
  env = buildEnv {
    name = "${release.pname}-build-env";
    paths = [ release ];
  };
in

mkShell rec {
  name = "${release.pname}-env";
  buildInputs = [
    env
    dieHook
  ];

  shellHook = ''
    source ${release.envShellHook}

    ${envLib.exportXdgDataDirsOf ([ release ] ++ release.buildInputs)}
    ${envLib.ensureDynamicBashCompletionLoaderInstalled}

    shell_dir="${toString ./.}"
    test -e "$shell_dir/env.sh" || die "Cannot find expected '$shell_dir/env.sh'!"

    export PKG_NIXOS_SF_FACTORY_INSTALL_PACKAGE_ROOT_DIR="$shell_dir"
    . "$shell_dir/env.sh"

    export PKG_NIXOS_SF_FACTORY_INSTALL_IN_ENV=1
  '';

  passthru.shellHook = shellHook;
}

