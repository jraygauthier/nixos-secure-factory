{ deviceIdentifier
, extraNixSearchPath ? {}
, workspaceDir ? null
}:

let
  deviceInfoJsonPath = null;
  nixpkgs = <nixpkgs>;
  pkgs = import nixpkgs {};
  inherit (pkgs) nix-gitignore;
  nixos-secure-factory =
    nix-gitignore.gitignoreSourcePure [
      ../.gitignore
      "/demo-nixos-config/\n"
    ]
    ../.;
in

pkgs.callPackage ./. {
  inherit deviceIdentifier extraNixSearchPath deviceInfoJsonPath;
  inherit nixos-secure-factory;
  inherit nixpkgs;
}
