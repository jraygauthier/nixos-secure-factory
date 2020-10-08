{ pkgs ? null
, workspaceDir ? null
, fromNixosModule ? false
}:

# When `pkgs == null`, the drawbacks are:
#  -  `nsf-pin` cli tools are not available.
#  -  A pin's `default.nix` file won't be able to receive packages
#     from `pkgs` as input.
# Usually, one should set pkgs to null only when pinning `nixpkgs`
# itself or when one want to avoid using `nixpkgs`.

# When non null, should be a path or if a string, an absolute path.
assert null == workspaceDir
  || (builtins.isPath workspaceDir)
  || ("/" == builtins.substring 0 1 workspaceDir);

let
  pinnedSrcsDir = ./pinned-src;
  nsfp = rec {
    localPath = /. + workspaceDir + "/nsf-pin";
    srcInfoJson = pinnedSrcsDir + "/nsf-pin/channel/default.json";
    srcInfo = builtins.fromJSON (builtins.readFile srcInfoJson);
    channels =
      assert srcInfo.type == "fetchFromGitHub";
      with srcInfo;
      {
        default = rec {
          version = {
            inherit ref rev;
            url = "https://github.com/${owner}/${repo}";
          };
          src = builtins.fetchTarball (with version; {
            url = "${url}/archive/${rev}.tar.gz";
            sha256 = "${srcInfo.sha256}";
          });
        };
      };

    pinnedSrcPath = channels.default.src;
    srcPath =
      if null != workspaceDir
          && builtins.pathExists localPath
        then localPath
        else pinnedSrcPath;

    nixLib = (import (srcPath + "/release.nix") { inherit pkgs; }).nix-lib;
  };
in

rec {
  srcs = nsfp.nixLib.mkSrcDir {
    inherit pinnedSrcsDir;
    inherit workspaceDir;
    inherit pkgs;
    srcPureIgnores = {
      default = ''
        /.git/
        **/.pytest_cache/
        **/.mypy_cache/
        **/__pycache__/
        /.vscode/
        **/result
      '';
    };
  };

  # TODO: Automate this.
  # TODO: At least, ensure that nothing is missing.
  nixosPickedSrcs = {
    # TODO: Missing name attr.
    nixos-secure-factory =
      { src = <nixos-secure-factory>; version = <nixos-secure-factory-version>; };
    nsf-ssh-auth =
      { src = <nsf-ssh-auth>; version = <nsf-ssh-auth-version>; };
    nixpkgs =
      { src = <nixpkgs>; version = <nixpkgs-version>; };
    nsf-pin =
      { src = <nsf-pin>; version = <nsf-pin-version>; };
  };

  pickedSrcs =
    if fromNixosModule
      then nixosPickedSrcs
    else
      builtins.mapAttrs (k: v: v.default) srcs.localOrPinned;

  nixpkgs = pickedSrcs.nixpkgs.src;

  # This repo's overlay.
  overlay = self: super:
    let
      nsf-ssh-auth = (import
        (pickedSrcs.nsf-ssh-auth.src + "/release.nix")
        { pkgs = self; });
    in
  {
    nsf-ssh-auth-nix-lib = nsf-ssh-auth.nix-lib;
    # TODO: Remove. Only to demonstrate the
    # expected overlay behavior.
    nsf-ssh-auth-cli = nsf-ssh-auth.cli;
  };

  # The set of overlays used by this repo.
  overlays = [ overlay ];
}
