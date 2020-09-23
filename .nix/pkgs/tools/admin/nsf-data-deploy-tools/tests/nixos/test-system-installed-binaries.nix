{ nixpkgs, system, default, nsf-test-lib, commonGitIgnores }:

with import (nixpkgs + "/nixos/lib/testing.nix") { inherit system; };

makeTest (

let
  mkNixosTestPkg = { testName, runTimeDeps, testPath }:
    with pkgs;
    assert lib.isString testPath;
    stdenv.mkDerivation rec {
      pname = "${default.pname}-tests-${testName}";
      name = pname;
      src = nix-gitignore.gitignoreSourcePure (commonGitIgnores ++ [
        ''
          /bin/
          /sh-lib/
          /Makefile
          /README.md
        ''
        ]) ../..;

      customPython = pkgs.python3.withPackages (pp: with pp; [
        pytest
        nsf-test-lib
      ]);

      nativeBuildInputs = with pkgs; [ tree makeWrapper ];

      buildInputs = [
        customPython
      ] ++ runTimeDeps;

      buildPhase = "true";

      installPhase = ''
        share_dir="$out/share/${pname}"
        mkdir -p "$share_dir"
        for f in $(find "." -mindepth 1 -maxdepth 1); do
          cp -R -t "$share_dir" "$f"
        done

        mkdir -p "$out/bin"
        makeWrapper "${customPython}/bin/pytest" "$out/bin/pytest-run-tests-${testName}" \
          --add-flags "--color yes" \
          --add-flags "'$share_dir/${testPath}'"
      '';
    };

    releaseNixosTestsInstalled = mkNixosTestPkg rec {
      testName = "installed";
      runTimeDeps = [];
      testPath = "./tests/${testName}";
    };
in

{
  nodes =
    { device =
        { config, pkgs, ... }:
        {
          users.mutableUsers = false;

          users.groups = {
            nsft-other-group = {
              gid = 1050;
            };
            nsft-yet-another-group = {
              gid = 1051;
            };
          };

          users.extraUsers = {
            nsft-other-user = {
              isNormalUser = true;
              uid = 1020;
              extraGroups = [
                "nsft-other-group"
              ];
            };

            nsft-yet-another-user = {
              isNormalUser = true;
              uid = 1021;
              extraGroups = [
                "nsft-other-group"
                "nsft-yet-another-group"
              ];
            };
          };

          environment.systemPackages = [
              default
              releaseNixosTestsInstalled
          ];
        };
    };

  testScript = { nodes }:
    ''
      startAll;
      # $device->log("pkg-nsf-data-deploy-tools-get-sh-lib-dir");
      $device->succeed("pkg-nsf-data-deploy-tools-get-sh-lib-dir");
      # $device->log("pytest-run-tests-installed");
      $device->succeed("pytest-run-tests-installed");
    '';
})
