{ stdenv, lib, fetchFromGitHub, makeWrapper, openssh }:

stdenv.mkDerivation rec {
  name = "rsshfs-${version}";
  version = "unstable-2014-06-17";

  src = fetchFromGitHub {
    owner = "rom1v";
    repo = "rsshfs";
    rev = "9758f70eac6a15ba31009f9fc6a7cfb989b1b110";
    sha256 = "11rmv9gn692hx5h6kc6g093jh49h4r7mpysdcgwz45m6f8d1sw3g";
  };

  /*
    TODO:

     -  [add ssh identityfile option · d-a-v/rsshfs@2b478f2](https://github.com/d-a-v/rsshfs/commit/2b478f205ce9127c72259d826f7d72de95986d3b)
     -  Add a ssh port option.
  */

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssh ];

  postPatch = ''
    substituteInPlace ./rsshfs --replace "/usr/lib/openssh/sftp-server" "${openssh}/libexec/sftp-server"
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./rsshfs $out/bin/rsshfs
    chmod a+x $out/bin/rsshfs
    wrapProgram $out/bin/rsshfs \
      --prefix PATH : ${stdenv.lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "Reverse of sshfs";
    license = licenses.gpl3;
    homepage = https://github.com/rom1v/rsshfs;
    maintainers = [ maintainers.jraygauthier ];
  };
}
