{}:

rec {
  fetchGitPinnedChannel = channelSrcInfo:
    let
      fetchGitExpectedAttr = { "url" = null; "ref" = null; "rev" = null; };
      filteredSrcInfo = builtins.intersectAttrs fetchGitExpectedAttr channelSrcInfo;
      src = builtins.fetchGit filteredSrcInfo;
    in {
      inherit src;
      version = {
        type = "git";
        inherit (channelSrcInfo) url ref rev;
      };
    };

  fetchGithubPinnedChannel = channelSrcInfo:
    let
      fetchGitExpectedAttr = { "owner" = null; "repo" = null; "ref" = null; "rev" = null; };
      filteredSrcInfo = builtins.intersectAttrs fetchGitExpectedAttr channelSrcInfo;
      src = builtins.fetchTarball {
        url = "https://github.com/${channelSrcInfo.owner}/${channelSrcInfo.repo}/archive/${channelSrcInfo.rev}.tar.gz";
        sha256 = channelSrcInfo.sha256;
      };
    in {
      inherit src;
      version = {
        type = "git";
        url = "https://github.com/${channelSrcInfo.owner}/${channelSrcInfo.repo}";
        inherit (channelSrcInfo) ref rev;
      };
    };

  fetchPinnedChannelJson = channelJsonPath:
      let
        channelSrcInfo = builtins.fromJSON (builtins.readFile (channelJsonPath));
        channelType = channelSrcInfo.type;

        typeToFetcherFn = {
          "builtins.fetchGit" = fetchGitPinnedChannel;
          "fetchFromGitHub" = fetchGithubPinnedChannel;
        };

        assertFetcherTypeSupported =
          if typeToFetcherFn ? channelType
          then true
          else builtins.trace
            "Pinned channel Fetcher type '${channelType}' is not supported."
            false;

        fetchFn = typeToFetcherFn."${channelType}";

      in
    fetchFn channelSrcInfo;

  fetchPinnedChannels = srcRootDir: channelsDir:
      let
        # The `srcRootDir` is required merely to improve
        # error messages.
        srcName = "${baseNameOf (toString srcRootDir)}";
        toChannelNames = bn:
            let
              splitted = builtins.split "^([^\.]+).json$" bn;
            in
          if 3 != builtins.length splitted
            then []
            else builtins.elemAt splitted 1;

        chanelDirContent = (builtins.attrNames (builtins.readDir channelsDir));
        channelNames = builtins.foldl' (acc: bn:  acc ++ toChannelNames bn) [] chanelDirContent;

        channelJsonFileAttrs =
            let
              toNVTuple = cname: {name = cname; value = channelsDir + "/${cname}.json"; };
            in
          builtins.listToAttrs (builtins.map toNVTuple channelNames);

        fetchedChannels =
          builtins.mapAttrs (cname: cjson: fetchPinnedChannelJson cjson) channelJsonFileAttrs;

        assertHasDefaultChannel =
          if fetchedChannels ? "default"
          then true
          else builtins.trace
            "Pinned source '${srcName}' does not expose the mandatory 'default' channel."
            false;
      in
    assert assertHasDefaultChannel;
    fetchedChannels;
}