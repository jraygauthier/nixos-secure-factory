{ deviceIdentifier
, extraNixSearchPath ? {}
, workspaceDir ? null
}:

let
  libSrc = import ./lib/src.nix { inherit workspaceDir; };
  deviceInfoJsonPath = null;
  nixpkgsSrc = <nixpkgs>;
  nixpkgs = import nixpkgsSrc {};
  inherit (nixpkgs) nix-gitignore;
  nixos-secure-factory =
    nix-gitignore.gitignoreSourcePure [
      ../.gitignore
      "/demo-nixos-config/\n"
    ]
    ../.;
in

nixpkgs.pkgs.callPackage ./. {
  inherit deviceIdentifier extraNixSearchPath deviceInfoJsonPath;
  inherit nixpkgsSrc nixpkgs nixos-secure-factory;
}
