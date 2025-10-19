# This overlay adds all packages from this repository directly into your main `pkgs` set.
# Using this overlay may cause package name conflicts.
self: super:
let
  isReserved = n: n == "lib" || n == "overlays" || n == "modules";
  nameValuePair = n: v: {
    name = n;
    value = v;
  };
  nurAttrs = import ../default.nix { pkgs = super; };
in
builtins.listToAttrs (
  map (n: nameValuePair n nurAttrs.${n}) (
    builtins.filter (n: !isReserved n) (builtins.attrNames nurAttrs)
  )
)
