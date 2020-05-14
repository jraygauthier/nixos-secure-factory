{}:

let
  repoName = "nsf-pin";
  wsDir = ../../..;
  localRepoDir = wsDir + "/${repoName}";
  out = if builtins.pathExists localRepoDir
    then {
      # TODO: Filter this somehow.
      src = localRepoDir;
      url = localRepoDir;
      ref = "unknown";
      rev = "unknown";
    }
    else
      (import (../pinned-src + "/${repoName}/default.nix") {}).default;
in

out
