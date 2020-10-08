{ lib
, buildPythonPackage
, click
, pyyaml
, nsf-ssh-auth-cli
, nsf-shc-nix-lib
}:

buildPythonPackage rec  {
  pname = "nsf-factory-common-install-py";
  version = "0.1.0";
  src = ./.;
  buildInputs = [];

  doCheck = false;

  propagatedBuildInputs = [
    click
    pyyaml
    nsf-ssh-auth-cli
  ];

  # dontWrapPythonPrograms = true;

  postFixup = with nsf-shc-nix-lib; ''
    # We need to patch programs earlier as we
    # need to run some of these in order to produce bash
    # completions just below.
    patchShebangs "$out/bin"

    ${nsfShC.pkg.installClickExesBashCompletion [
      "device-common-ssh-auth-dir"
      "device-ssh-auth-dir"
      "device-state"
      "device-current-state"
    ]}
  '';
}
