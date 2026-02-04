{
  lib,
  fetchFromGitHub,
  fetchurl,
  qemu_kvm,
  # build time
  perl,
  # runtime
  libuuid,
  ...
}:
let
  proxmoxPatchSrc = fetchFromGitHub rec {
    pname = "pve-qemu-src";
    version = "1d0e04fc9e98866a87c6bd0ae9fafa50ea585a48";

    owner = "proxmox";
    repo = "pve-qemu";
    rev = version;
    hash = "sha256-5l2aWgwmlO4he7Mwim09bPNVNR7IHVABkxFMbjhKYrg=";
  };

  # Disable unneeded features to reduce build time
  minimalQemu = qemu_kvm.override {
    alsaSupport = false;
    pulseSupport = false;
    sdlSupport = false;
    jackSupport = false;
    gtkSupport = false;
    vncSupport = false;
    smartcardSupport = false;
    spiceSupport = false;
    ncursesSupport = false;
    libiscsiSupport = false;
    tpmSupport = false;
    numaSupport = false;
    seccompSupport = false;
    guestAgentSupport = false;
  };
in
minimalQemu.overrideAttrs (super: rec {
  pname = "proxmox-vma";
  version = "10.1.2";

  src = fetchurl {
    url = "https://download.qemu.org/qemu-${version}.tar.xz";
    hash = "sha256-nXXzMcGly5tuuP2fZPVj7C6rNGyCLLl/izXNgtPxFHk=";
  };

  outputs = [ "out" ];
  separateDebugInfo = false;

  patches = [
    "${proxmoxPatchSrc}/debian/patches/pve/0027-PVE-Backup-add-vma-backup-format-code.patch"
  ];

  nativeBuildInputs = super.nativeBuildInputs ++ [ perl ];
  buildInputs = super.buildInputs ++ [ libuuid ];

  postInstall = ''
    # Delete standard QEMU binaries to reduce closure size
    find $out/bin -type f -not -name 'vma' -delete

    # Cleanup artifacts
    rm -rf $out/share $out/libexec $out/include

    if [ ! -e "$out/bin/vma" ]; then
        echo "Error: vma binary was not built!"
        exit 1
    fi
  '';

  passthru = {
    updateScript = ./update.sh;
    inherit proxmoxPatchSrc;
  };

  meta = {
    description = "Proxmox VMA (Virtual Machine Archive) tool patched into QEMU";
    homepage = "https://git.proxmox.com/?p=pve-qemu.git";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
})
