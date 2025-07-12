{
  stdenv,
  lib,
  fetchurl
}:

stdenv.mkDerivation rec {
  pname = "adguardhome";
  version = "0.108.0-b.72";

  src = fetchurl {
    url = "https://github.com/AdguardTeam/AdGuardHome/releases/download/v${version}/AdGuardHome_linux_amd64.tar.gz";
    hash = "sha256-3C6WyybU7nv0BcdSdyHYkR7sapRWA/BY9M8MNocnBj0=";
  };

  installPhase = ''
    install -m755 -D ./AdGuardHome $out/bin/adguardhome
  '';

  meta = with lib; {
    homepage = "https://github.com/AdguardTeam/AdGuardHome";
    description = "Network-wide ads & trackers blocking DNS server";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}