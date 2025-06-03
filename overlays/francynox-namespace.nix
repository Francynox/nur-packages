final: prev: {
  francynox =
    let
      nurAllAttrs = import ../default.nix { pkgs = prev; };
    in
    prev.lib.filterAttrs (name: value: prev.lib.isDerivation value) nurAllAttrs;
}
