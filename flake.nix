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
        (import ./per-system.nix) {
          inherit nixpkgs system;
        };

    in
    {
      formatter = forAllSystems (system: (perSystem system).formatter);
      legacyPackages = forAllSystems (system: (perSystem system).legacyPackages);
      packages = forAllSystems (system: (perSystem system).packages);
      checks = forAllSystems (system: (perSystem system).checks);
      ciJobs = forAllSystems (system: (perSystem system).ciJobs);

      nixosModules = nurModules;
      overlays = nurOverlays;
    };
}
