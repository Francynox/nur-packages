{
  stdenv,
  lib,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "adguardhome";
  version = "0.108.0-b.79";

  src = fetchurl {
    url = "https://github.com/AdguardTeam/AdGuardHome/releases/download/v${version}/AdGuardHome_linux_amd64.tar.gz";
    hash = "sha256-M7Dd88zc21iMcuylIY+h4vsGfbtq2jZlecaFrGOIykU=";
  };

  installPhase = ''
    install -m755 -D ./AdGuardHome $out/bin/adguardhome
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    homepage = "https://github.com/AdguardTeam/AdGuardHome";
    description = "Network-wide ads & trackers blocking DNS server";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
