{
  stdenv,
  lib,
  fetchurl,

  # build time
  perl,
  pkg-config,
  removeReferencesTo,

  # runtime
  libidn2,
  libtool,
  libxml2,
  openssl,
  liburcu,
  libuv,
  nghttp2,
  jemalloc,
  libcap
}:

stdenv.mkDerivation rec {
  pname = "bind";
  version = "9.21.8";

  src = fetchurl {
    url = "https://downloads.isc.org/isc/bind9/${version}/${pname}-${version}.tar.xz";
    hash = "sha256-Ze4eZAtzDp/Yyx4SLlFG8D+t4+QQXRAGahNx2Ssgy0Q=";
  };

  patches = [
    ./dont-keep-configure-flags.patch
  ];

  nativeBuildInputs = [
    perl
    pkg-config
    removeReferencesTo
  ];
  
  buildInputs = [
      libidn2
      libtool
      libxml2
      openssl
      liburcu
      libuv
      nghttp2
      jemalloc
      libcap
    ];

  configureFlags = [
      "--localstatedir=/var"
      "--without-lmdb"
      "--with-libidn2"
      "--disable-geoip"
    ];

  postInstall = ''
    for f in "$out/lib/"*.la; do
      sed -i "$f" -e 's|-L${openssl.dev}|-L${lib.getLib openssl}|g'
    done
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://www.isc.org/bind/";
    description = "ISC BIND - Domain Name Server";
    license = licenses.mpl20;
    platforms = [ "x86_64-linux" ];
  };
}