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
  # Optional package set in case the pinned channel helpers
  # requires some dependencies. By default / for most uses,
  # it shouldn't.
, nixpkgs ? null
}:

let
  pkgs = if null == nixpkgs then {} else nixpkgs;

  optionalAttrs = cond: as: if cond then as else {};

  callFnWith = autoArgs: fn: args:
    let
      f = if builtins.isFunction fn then fn else (import fn);
      auto = builtins.intersectAttrs (builtins.functionArgs f) autoArgs;
    in (f (auto // args));

  callFn = callFnWith pkgs;

  getPinnedSrc = pname:
      let
        pinnedChannel = (callFn (pinnedSrcsDir + "/${pname}/default.nix") {}).default;
      in pinnedChannel;
in

{
  inherit getPinnedSrc;
} // optionalAttrs (workspaceDir != null) rec {
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
