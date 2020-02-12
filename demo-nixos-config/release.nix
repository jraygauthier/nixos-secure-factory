{ device_identifier ? null # TODO: Deprecated. Remove.
, deviceIdentifier ? device_identifier # TODO: Make mandatory once above removed.
, extraNixSearchPath ? {}
, workspaceDir ? null
}:

assert null != deviceIdentifier;

let
  libSrc = import ./lib/src.nix { inherit workspaceDir; };
  deviceInfoJsonPath = null;
  nixpkgs_src = <nixpkgs>;
  nixpkgs = import nixpkgs_src {};
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
  inherit nixpkgs_src nixpkgs nixos-secure-factory;
}
