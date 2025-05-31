{
  stdenv,
  lib,
  fetchurl,

  # build time
  pkg-config,
  meson,
  ninja,
  python3,

  # runtime
  boost,
  log4cplus,
  openssl
}:

stdenv.mkDerivation rec {
  pname = "kea";
  version = "2.7.9";

  src = fetchurl {
    url = "https://downloads.isc.org/isc/${pname}/${version}/${pname}-${version}.tar.xz";
    hash = "sha256-pUSRb2khVUOYFbcm/GBA/63DgVkfZ6f7EDGS1wU+vJI=";
  };

  patches = [
    ./dont-create-var.patch
  ];

  preConfigure = ''
    patchShebangs scripts/grabber.py
  '';

  mesonFlags = [
    "-Dlocalstatedir=/var"
    "-Dsysconfdir=${placeholder "out"}/etc"
    "-Dcrypto=openssl"
    "-Dkrb5=disabled"
    "-Dmysql=disabled"
    "-Dnetconf=disabled"
    "-Dpostgresql=disabled"
  ];

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    python3
  ];

  buildInputs = [
    boost
    log4cplus
    openssl
  ];

  meta = with lib; {
    homepage = "https://kea.isc.org/";
    description = "ISC KEA - DHCP server";
    license = licenses.mpl20;
    platforms = [ "x86_64-linux" ];
  };
}