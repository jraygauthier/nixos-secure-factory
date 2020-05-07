{ nixpkgs ? <nixpkgs>
, pkgs ? import nixpkgs {} }:

let
  inherit (pkgs)
    lib
    callPackage
    python3Packages
    mkShell
    bash-completion;

  envLib = import ../../../lib/env.nix {
      inherit lib bash-completion;
    };

  nixos-sf-ssh-auth-cli = (
    import ../../../pkgs/tools/admin/nixos-sf-ssh-auth/release.nix {
      inherit pkgs nixpkgs;
    }).python-lib;

  default = python3Packages.callPackage ./. {
      inherit nixos-sf-ssh-auth-cli;
    };
  defaultWDevTools = default.override {
      withDevTools = true;
    };

  env = mkShell {
      name = "${default.pname}-env";

      buildInputs = [ default ];

      shellHook = ''
        ${envLib.exportXdgDataDirsOf ([ default ] ++ default.buildInputs)}
        ${envLib.ensureDynamicBashCompletionLoaderInstalled}
      '';
    };

in

rec {
  inherit env default;

  shell = {
    dev = mkShell rec {
      name = "${defaultWDevTools.pname}-build-shell";
      inputsFrom = [
        defaultWDevTools
      ];
    };
  };
}
