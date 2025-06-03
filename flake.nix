{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      nurContents = forAllSystems (system: import ./default.nix {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      legacyPackages = nurContents;
      packages = forAllSystems (system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) nurContents.${system});
      overlays = forAllSystems (system: nurContents.${system}.overlays.namespace);
    };
}
