{ deviceIdentifier
, extraNixSearchPath ? {}
, workspaceDir ? null
}:

let
  deviceInfoJsonPath = null;
  nixpkgs = (import ./.nix/default.nix {}).nixpkgs;
  pkgs = import nixpkgs {};
  inherit (pkgs) nix-gitignore;
  nixos-secure-factory =
    nix-gitignore.gitignoreSourcePure [
      ../.gitignore
      "/demo-nixos-config/\n"
    ]
    ../.;

  pinnedSrcs = (
    import ../.nix/default.nix { inherit workspaceDir; }).srcs.pinned;

  pickedSrcs = {
    nsf-ssh-auth = pinnedSrcs.nsf-ssh-auth.default;
  };
in

pkgs.callPackage ./. {
  inherit deviceIdentifier extraNixSearchPath deviceInfoJsonPath;
  inherit nixos-secure-factory;
  inherit nixpkgs;
  inherit pickedSrcs;
}
