{ stdenv
, makeWrapper
, nixos-common-install-scripts
, gnugrep
, usbutils
, procps
, parted
, lvm2
, nix
# , nixos-install
# , nixos-generate-config
# , util-linux
, openssh
, gnupg
, sshfs-fuse
, gopass
, usermount
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-device-common-install-scripts";
  name = "${pname}-${version}";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  propagatedUserEnvPkgs = [ nixos-common-install-scripts ];
  buildInputs = [
    nixos-common-install-scripts
    gnugrep
    parted
    usbutils
    procps
    lvm2
    openssh # ssh-keygen
    gnupg
    sshfs-fuse
    gopass
    usermount # fusermount
    # We will assume this is present and provided by the livecd.
    # util-linux # mkswap, wipefs, mountpoint, swapon, lsblk
    # nix
    # nixos-install
    # nixos-generate-config
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg-nixos-device-common-install-get-libexec-dir \
      --replace 'default_pkg_dir/libexec' 'default_pkg_dir/${pname}/libexec' \
  '';

  installPhase = ''
    mkdir -p "$out/${pname}/libexec"
    cp -p "./libexec/"* "$out/${pname}/libexec"

    for cmd in $(find ./bin -mindepth 1 -maxdepth 1); do
      cmd_basename="$(basename $cmd)"
      install -vD $cmd $out/bin/$cmd_basename;
      wrapProgram $out/bin/$cmd_basename \
        --prefix PATH : ${stdenv.lib.makeBinPath buildInputs}
    done
  '';

  meta = {
    description = ''
      Some common scripts meant to be run on new nixos devices when first installed.
    '';
  };

}
