{ nixpkgs, system }:

let
  pkgs = import nixpkgs { inherit system; };

  nur = import ./default.nix { inherit pkgs; };

  pkgsForTests = import nixpkgs {
    inherit system;
    overlays = [ nur.overlays.namespace ];
  };

  tests = import ./tests {
    pkgs = pkgsForTests;
    modules = nixpkgs.lib.attrValues nur.modules;
  };

  isSupported =
    package:
    let
      platforms = package.meta.platforms or null;
    in
    nixpkgs.lib.isDerivation package
    && (
      platforms == null
      || builtins.any (p: nixpkgs.lib.meta.platformMatch pkgs.stdenv.hostPlatform p) platforms
    )
    && !(package.meta.broken or false);

  isFree =
    package:
    let
      licenseFromMeta = package.meta.license or [ ];
      licenseList = if builtins.isList licenseFromMeta then licenseFromMeta else [ licenseFromMeta ];
    in
    builtins.all (license: license.free or true) licenseList;

  isCheckable =
    testName:
    let
      package = nur.${testName};
    in
    (builtins.hasAttr testName nur) && isSupported package;

  isLocalBuild = package: package.preferLocalBuild or false;

  isCachablePackage = package: isFree package && isSupported package && !isLocalBuild package;

  isCachableCheck =
    testName: if builtins.hasAttr testName nur then isCachablePackage nur.${testName} else true;

  filteredPackages = nixpkgs.lib.filterAttrs (_: v: isCachablePackage v) nur;
  filteredChecks = nixpkgs.lib.filterAttrs (n: _: isCachableCheck n) tests;
in
{
  formatter = pkgs.nixfmt-tree;
  legacyPackages = nur;
  packages = nixpkgs.lib.filterAttrs (_: v: isSupported v) nur;
  checks = nixpkgs.lib.filterAttrs (n: _: isCheckable n) tests;
  ciJobs =
    let
      pkgsMap = nixpkgs.lib.mapAttrs' (n: v: nixpkgs.lib.nameValuePair "pkg-${n}" v) filteredPackages;
      checksMap = nixpkgs.lib.mapAttrs' (n: v: nixpkgs.lib.nameValuePair "check-${n}" v) filteredChecks;
    in
    pkgsMap // checksMap;
}
