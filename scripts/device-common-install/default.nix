{ stdenv
, makeWrapper
, nixos-common-install-scripts
, coreutils
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
, sshfs-fuse
, usermount
, bashInteractive
}:

stdenv.mkDerivation rec {
  version = "0.0.0";
  pname = "nixos-device-common-install";
  name = "${pname}-${version}";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  propagatedUserEnvPkgs = [ nixos-common-install-scripts ];
  buildInputs = [
    nixos-common-install-scripts
    coreutils
    gnugrep
    parted
    usbutils
    procps
    lvm2
    openssh # ssh-keygen
    sshfs-fuse
    usermount # fusermount
    # We will assume this is present and provided by the livecd.
    # util-linux # mkswap, wipefs, mountpoint, swapon, lsblk
    # nix
    # nixos-install
    # nixos-generate-config
  ];

  postPatch = ''
    substituteInPlace ./bin/pkg-${pname}-get-libexec-dir \
      --replace 'default_pkg_dir=' '# default_pkg_dir=' \
      --replace '$default_pkg_dir/libexec' "$out/share/${pname}/libexec"

    substituteInPlace ./bin/pkg-${pname}-get-root-dir \
      --replace 'default_pkg_dir=' '# default_pkg_dir=' \
      --replace '$default_pkg_dir' "$out/share/${pname}"

    ! test -e "./.local-env.sh" || rm ./.local-env.sh
  '';

  installPhase = ''
    mkdir -p "$out/share/${pname}"
    find . -mindepth 1 -maxdepth 1 -exec mv -t "$out/share/${pname}" {} +

    mkdir -p "$out/bin"
    for cmd in $(find "$out/share/${pname}/bin" -mindepth 1 -maxdepth 1); do
      target_cmd_basename="$(basename "$cmd")"
      makeWrapper "$cmd" "$out/bin/$target_cmd_basename" \
        --prefix PATH : "${stdenv.lib.makeBinPath buildInputs}" \
        --prefix PATH : "$out/share/${pname}/bin"
    done
  '';

  # Principally required for read -e -i 'Default value'.
  preFixup = ''
    PATH="${bashInteractive}/bin:$PATH" patchShebangs "$out"
  '';

  meta = {
    description = ''
      Some common scripts meant to be run on new nixos devices when first installed.
    '';
  };

}
