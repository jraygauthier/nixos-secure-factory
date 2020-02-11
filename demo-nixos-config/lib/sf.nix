{ workspaceDir ? null }:

let
  sf_pinned_channels = let
    defaultChannelJson = ../pkgs/pinned-src/nixos-secure-factory/channel/default.json;
    channelSrcInfo = builtins.fromJSON (builtins.readFile defaultChannelJson);
    version =
        assert channelSrcInfo.type == "fetchFromGitHub";
        with channelSrcInfo; {
      inherit ref rev;
      url = "https://github.com/${owner}/${repo}";
    };
    src = builtins.fetchTarball (with version; {
      url = "${url}/archive/${rev}.tar.gz";
      sha256 = "${channelSrcInfo.sha256}";
    });
  in {
    default = {
      inherit src version;
    };
  };

  pinnedSrc = sf_pinned_channels.default.src;

  # workspaceDir =  builtins.toString ../..;

  localPath = /. + workspaceDir + "/nixos-secure-factory";
  sfSrc =
    if null != workspaceDir
        && builtins.pathExists localPath
      then localPath
      else pinnedSrc;
in

sfSrc
