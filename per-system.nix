{ nixpkgs, system }:

let
  inherit (nixpkgs) lib;

  pkgs = import nixpkgs {
    inherit system;
    overlays = [ nur.overlays.namespace ];
    config.allowUnfree = true;
  };

  nur = import ./default.nix { inherit pkgs; };

  tests = import ./tests {
    inherit pkgs;
    modules = lib.attrValues nur.modules;
  };

  isSupported =
    p:
    lib.isDerivation p && lib.meta.availableOn pkgs.stdenv.hostPlatform p && !(p.meta.broken or false);

  isFree = p: lib.all (l: l.free or true) (lib.toList (p.meta.license or [ ]));

  isBuildable = p: isSupported p && !(p.preferLocalBuild or false);

  isCacheable = p: isBuildable p && isFree p;

  mkCi =
    condition:
    let
      selectedPkgs = lib.filterAttrs (_: p: condition p) nur;

      selectedTests = lib.filterAttrs (n: _: !(nur ? ${n}) || condition nur.${n}) tests;

      prefixAttrs = prefix: set: lib.mapAttrs' (n: v: lib.nameValuePair "${prefix}-${n}" v) set;
    in
    (prefixAttrs "pkg" selectedPkgs) // (prefixAttrs "check" selectedTests);
in
{
  formatter = pkgs.nixfmt-tree;
  legacyPackages = nur;
  packages = lib.filterAttrs (_: v: isSupported v) nur;
  checks = mkCi isSupported;
  ciJobs = mkCi isCacheable;
}
