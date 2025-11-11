{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      nurModules = import ./modules;
      nurOverlays = import ./overlays;

      systems = nixpkgs.lib.systems.flakeExposed;
      forAllSystems = nixpkgs.lib.genAttrs systems;

      perSystem =
        system:
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

          isCheckable =
            testName:
            let
              package = nur.${testName};
            in
            isSupported package;

        in
        {
          formatter = pkgs.nixfmt-tree;
          legacyPackages = nur;
          packages = nixpkgs.lib.filterAttrs (_: v: isSupported v) nur;
          checks = nixpkgs.lib.filterAttrs (n: _: isCheckable n) tests;
        };

    in
    {
      formatter = forAllSystems (system: (perSystem system).formatter);
      legacyPackages = forAllSystems (system: (perSystem system).legacyPackages);
      packages = forAllSystems (system: (perSystem system).packages);
      checks = forAllSystems (system: (perSystem system).checks);

      nixosModules = nurModules;
      overlays = nurOverlays;
    };
}
