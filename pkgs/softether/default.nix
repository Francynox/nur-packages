{
  stdenv,
  lib,
  fetchurl,

  # build time
  cmake,
  gcc,
  gnumake,
  pkgconf,

  # runtime
  ncurses,
  openssl,
  libsodium,
  readline,
  zlib
}:
stdenv.mkDerivation rec {
  pname = "softether";
  version = "5.02.5187";

  src = fetchurl {
    url = "https://github.com/SoftEtherVPN/SoftEtherVPN/releases/download/${version}/SoftEtherVPN-${version}.tar.xz";
    hash = "sha256-w85q4Fztb2HyhDfyExF9HOGDj73aNl99/VfwTcG9C0s=";
  };

  nativeBuildInputs = [
    cmake
    gcc
    gnumake
    pkgconf
  ];

  buildInputs = [
    ncurses
    openssl
    libsodium
    readline
    zlib
  ];

  configurePhase = ''
    mkdir -p $out/lib/systemd/system

    substituteInPlace CMakeLists.txt \
      --replace-fail "/lib/systemd/system" "$out/lib/systemd/system"

    CMAKE_FLAGS="-DSE_PIDDIR=/run/softether -DSE_LOGDIR=/var/log/softether -DSE_DBDIR=/var/lib/softether" CMAKE_INSTALL_PREFIX="$out" ./configure
  '';

  buildPhase = ''
    make -C build
  '';

  installPhase = ''
    make -C build install
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://www.softether.org/";
    description = "Open-Source Free Cross-platform Multi-protocol VPN Program";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
