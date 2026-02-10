{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "adguardhome";
  version = "0.108.0-b.82";

  src = fetchurl {
    url = "https://github.com/AdguardTeam/AdGuardHome/releases/download/v${version}/AdGuardHome_linux_amd64.tar.gz";
    hash = "sha256-ivsHaj/e6pytR8ej/tKRqsgz7PiFgOoOdUqKeMDXKVc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -m755 -D ./AdGuardHome $out/bin/adguardhome

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    homepage = "https://github.com/AdguardTeam/AdGuardHome";
    description = "Network-wide ads & trackers blocking DNS server";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "adguardhome";
  };
}
