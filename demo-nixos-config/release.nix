{ deviceIdentifier
, extraNixSearchPath ? {}
, workspaceDir ? null
}:

let
  deviceInfoJsonPath = null;
  nixpkgsSrc = <nixpkgs>;
  pkgs = import nixpkgsSrc {};
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
  inherit nixpkgsSrc nixos-secure-factory;
  # TODO: Non standard interface. Change this.
  nixpkgs = pkgs;
}
