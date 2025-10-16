{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      perSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          nurForSystem = import ./default.nix { inherit pkgs; };

          pkgsForTests = import nixpkgs {
            inherit system;
            overlays = [ nurForSystem.overlays.namespace ];
          };

          testsForSystem = import ./tests {
            pkgs = pkgsForTests;
            modules = nixpkgs.lib.attrValues nurForSystem.modules;
          };

        in
        {
          formatter = pkgs.nixfmt-tree;
          legacyPackages = nurForSystem;
          packages = nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) nurForSystem;
          nixosModules = nurForSystem.modules;
          overlays = nurForSystem.overlays.namespace;
          checks = nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) testsForSystem;
        };

    in
    {
      formatter = forAllSystems (system: (perSystem system).formatter);
      legacyPackages = forAllSystems (system: (perSystem system).legacyPackages);
      packages = forAllSystems (system: (perSystem system).packages);
      nixosModules = forAllSystems (system: (perSystem system).nixosModules);
      overlays = forAllSystems (system: (perSystem system).overlays);
      checks = forAllSystems (system: (perSystem system).checks);
    };
}
