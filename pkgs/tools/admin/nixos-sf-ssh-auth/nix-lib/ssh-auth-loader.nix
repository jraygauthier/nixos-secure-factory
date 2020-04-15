
{ lib
, stdenv
, yq
}:

rec {
  extendAttrsWSrcsInfo = srcDir: srcStem: srcFlns: attrs:
    assert ! (attrs ? "srcs");
    attrs // {
      srcs = [{
        dir = srcDir;
        stem = srcStem;
        files = srcFlns;
      }];
    };


  printSingleSrcPath = src:
    if 0 == lib.lists.length src.files
      then "defaultSrc[${builtins.toString (src.dir + "/${src.stem}")}]"
    else if 1 == lib.lists.length src.files
      then "${builtins.toString (lib.lists.head src.files)}"
    else
      "mergedFiles[${lib.strings.concatMapStringsSep ":" (fp: builtins.toString fp) src.files}]";


  printSrcPaths = srcs:
    assert 1 <= lib.lists.length srcs;
    if 1 == lib.lists.length srcs
      then printSingleSrcPath (lib.lists.head srcs)
    else
      "mergedSrcs[${lib.strings.concatMapStringsSep ":" printSingleSrcPath srcs}]";


  getSingleSrcDir = srcs:
    assert 1 == lib.lists.length srcs;
    (lib.lists.head srcs).dir;


  loadAttrsFromNixFile = fln:
      import fln;


  loadAttrsFromJsonFile = fln:
      builtins.fromJSON (
        builtins.readFile fln);


  loadAttrsFromYamlFile = fln:
      let
        jsonFile = stdenv.mkDerivation rec {
          name = "requirements-firmware.json";
          phases = [ "installPhase" ];

          nativeBuildInputs = [ yq ];

          installPhase = ''
            cat "${fln}" | yq '.' > "$out"
          '';
        };
      in
      builtins.fromJSON (
        builtins.readFile jsonFile);


  loadAttrsFromFile = formats: fln:
      let
        flnStr = builtins.toString fln;
        detectedFormat = lib.lists.findFirst (
            format: lib.strings.hasSuffix format.ext fln
          ) null formats;
        defaultLoaders = {
          nix = loadAttrsFromNixFile;
          json = loadAttrsFromJsonFile;
          yaml = loadAttrsFromYamlFile;
        };

        selectedLoader = defaultLoaders."${detectedFormat.ext}";

        suppFormatsEnumStr = lib.strings.concatStringsSep ", " (lib.attrNames formats);
        defaultLoadersEnumStr = lib.strings.concatStringsSep ", " (lib.attrNames defaultLoaders);
      in
    assert lib.asserts.assertMsg (builtins.pathExists fln)
      "File '${flnStr}' does not exists!";
    assert lib.asserts.assertMsg (detectedFormat != null)
      ( "No fileformat support for file '${flnStr}'. "
      + "Supported formats are: [${suppFormatsEnumStr}]."
      );
    assert lib.asserts.assertMsg (defaultLoaders ? "${detectedFormat.ext}")
      ( "No default loader for fileformat '${detectedFormat.ext}'. "
      + "Supported default loader formats: [${defaultLoadersEnumStr}]."
      );
    selectedLoader fln;


  loadAttrs = formats: dir: fCfg: default:
      let
        stem = fCfg.stem;
        potentialFlns = mkPathsForSupportedFormats formats dir stem;
        potentialFlnsStr = lib.strings.concatStringsSep "\n"
          (builtins.map builtins.toString potentialFlns);

        # TODO: Support loading all the existing file, combining them
        # (failing on duplicate attributes, merging list by concat).
        # IDEA: A higher level might be optionally passed in case
        # the default merge behavior is found lacking.
        foundFln = lib.lists.findFirst
          builtins.pathExists null potentialFlns;

        flns = if foundFln == null then [] else [ foundFln ];
      in

    extendAttrsWSrcsInfo dir stem flns (
      if fCfg.mandatoryFile || foundFln != null
        then
          assert lib.asserts.assertMsg (foundFln != null)
            ( "Cannot find file with stem '${stem}' under dir '${builtins.toString dir}'.\n"
            + "A load of the following locations was attempted: ''\n${potentialFlnsStr}\n''"
            );
          loadAttrsFromFile formats foundFln
      else
        assert (builtins.isAttrs default);
        default
    );


  mkPathFor = formatExt: dir: stem:
    dir + "/${stem}.${formatExt}";


  mkPathsForSupportedFormats = formats: dir: stem:
    lib.lists.map (format:
        mkPathFor format.ext dir stem
      )
      formats;


  mkPathForMainFormat = formats: dir: stem:
    mkPathFor (lib.lists.head formats).ext dir stem;


  getFirstAvailFlnOr = formats: dir: stem: default:
      lib.lists.findFirst (
          p: builtins.pathExists p
        )
        default
        (mkPathsForSupportedFormats formats dir stem);


  getFirstAvailFlnOrFstFln = formats: dir: stem:
    getFirstAvailFlnOr formats dir stem
      (mkPathForMainFormat formats dir stem);
}