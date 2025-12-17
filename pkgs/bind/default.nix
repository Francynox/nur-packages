{
  stdenv,
  lib,
  fetchurl,
  # build time
  meson,
  ninja,
  perl,
  pkg-config,
  # runtime
  liburcu,
  libuv,
  openssl,
  libcap,
  jemalloc,
  nghttp2,
  libxml2,
  json_c,
  zlib,
  libidn2,
  libedit,
}:
stdenv.mkDerivation rec {
  pname = "bind";
  version = "9.21.16";

  src = fetchurl {
    url = "https://downloads.isc.org/isc/${pname}9/${version}/${pname}-${version}.tar.xz";
    hash = "sha256-UhqiADxafXjY5Yl4cCXzk4QGVTWBj0NEz54UwIb9qY0=";
  };

  patches = [
    ./dont-keep-configure-flags.patch
  ];

  mesonFlags = [
    (lib.mesonEnable "cmocka" false)
    (lib.mesonEnable "dnstap" false)
    (lib.mesonEnable "doc" false)
    (lib.mesonEnable "doh" true)
    (lib.mesonEnable "fuzzing" false)
    (lib.mesonEnable "geoip" false)
    (lib.mesonEnable "gssapi" false)
    (lib.mesonEnable "idn" true)
    (lib.mesonEnable "jemalloc" true)
    (lib.mesonEnable "line" true)
    (lib.mesonEnable "lmdb" false)
    (lib.mesonEnable "stats-json" true)
    (lib.mesonEnable "stats-xml" true)
    (lib.mesonEnable "tracing" false)
    (lib.mesonEnable "zlib" true)
    (lib.mesonOption "localstatedir" "/var")
    (lib.mesonOption "sysconfdir" "/etc/bind")
  ];

  nativeBuildInputs = [
    meson
    ninja
    perl
    pkg-config
  ];

  buildInputs = [
    liburcu
    libuv
    openssl
    libcap
    jemalloc
    nghttp2
    libxml2
    json_c
    zlib
    libidn2
    libedit
  ];

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    homepage = "https://www.isc.org/bind/";
    description = "ISC BIND - Domain Name Server";
    license = licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "named";
  };
}
