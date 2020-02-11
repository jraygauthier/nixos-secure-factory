{}:

{
  srcHelpers = import ./src-helpers.nix;
  pinnedSrcHelpers = import ./pinned-src-helpers.nix;
  env = import ./env.nix;
  bashCompletions = import ./bash-completions.nix;
}
