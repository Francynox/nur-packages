# This overlay adds all packages from this repository directly into your main `pkgs` set.
# Using this overlay may cause package name conflicts.
final: prev:

let
  nurAttrs = import ../default.nix { pkgs = final; };

  reserved = [
    "lib"
    "overlays"
    "modules"
    "ciJobs"
    "checks"
  ];

  isReserved = n: builtins.elem n reserved;
in
prev.lib.filterAttrs (n: v: !isReserved n) nurAttrs
