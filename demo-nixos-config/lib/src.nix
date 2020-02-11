{ nixpkgs ? import ../pkgs/pinned/nixpkgs.nix {}
, workspaceDir ? null
}:

let
  srcIgnores = import ./src-ignore.nix {};
  sfLib = import ./sf-lib.nix { inherit workspaceDir;};

  srcHelpers = sfLib.srcHelpers {
    inherit workspaceDir;
    pinnedSrcsDir = ../pkgs/pinned-src/.;
    localSrcFilter = pname: localSrc: pinnedSrc:
      nixpkgs.nix-gitignore.gitignoreSourcePure (
          if srcIgnores ? "${pname}"
          then [ srcIgnores."${pname}" ]
          else [ srcIgnores.default ]
        )
        localSrc;
  };

in

srcHelpers