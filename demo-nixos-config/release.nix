{ device_identifier
, extra_nix_search_path ? {}
, device_info_json_file ? null
, workspaceDir ? null
}:

let
  libSrc = import ./lib/src.nix { inherit workspaceDir; };
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
  inherit device_identifier extra_nix_search_path device_info_json_file;
  inherit nixpkgs_src nixpkgs nixos-secure-factory;
}
