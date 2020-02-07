{
  # Where to find the per src channels (e.g.: ../pkgs/pinned-src).
  pinnedSrcsDir
  # Where to find the dependencies / other local repos.
  # Usually alongside this repository. Default to null.
  # When `null`, the *local* helpers won't be available.
, workspaceDir
  # A filter allowing custom removal of local src files.
  # Identity filter by default.
, localSrcFilter ? pname: localSrc: pinnedSrc: localSrc
, nixpkgs ? import <nixpkgs> {}
}:

let
  pinnedPkgs = nixpkgs;
  lib = pinnedPkgs.lib;

  callFnWith = autoArgs: fn: args:
    let
      f = if lib.isFunction fn then fn else (import fn);
      auto = builtins.intersectAttrs (lib.functionArgs f) autoArgs;
    in (f (auto // args));

  callFn = callFnWith pinnedPkgs;

  getPinnedSrc = pname:
      let
        pinnedChannel = (callFn (pinnedSrcsDir + "/${pname}/default.nix") {}).default;
      in pinnedChannel;
in

{
  inherit getPinnedSrc;
} // lib.attrsets.optionalAttrs (workspaceDir != null) rec {
  /*
    The following are only available when a workspace directory is specified.
    Basically, `getLocalOrPinnedSrc` allow one to retrieve the a local
    version of the src under the specified workspace directory fallbacking on the
    pinned version if the local one does no exists.
  */
  existLocalSrc = pname:
      let
        localSrc = workspaceDir + "/${pname}";
      in
    builtins.pathExists localSrc;

  getLocalOrPinnedSrc = pname:
      let
        localSrc = workspaceDir + "/${pname}";
        pinnedSrc = getPinnedSrc pname;
        filteredLocalSrc = rec {
          src =
            localSrcFilter pname localSrc pinnedSrc.src;
          version = {
            type = "local";
            url = src;
          };
        };
      in
    if (existLocalSrc pname) then filteredLocalSrc else pinnedSrc;
}
