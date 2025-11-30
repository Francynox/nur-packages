{
  description = "My personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        withSystem,
        lib,
        config,
        ...
      }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        imports = [
          treefmt-nix.flakeModule
          ./per-system.nix
        ];

        flake = {
          nixosModules = import ./modules;
          overlays = import ./overlays;
          ciJobs = lib.genAttrs config.systems (system: (withSystem system ({ config, ... }: config.ciJobs)));
        };
      }
    );
}
