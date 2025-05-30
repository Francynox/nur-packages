# Francynox Nix User Repository

![Build and populate cache](https://github.com/Francynox/nur-packages/workflows/Build%20and%20populate%20cache/badge.svg)
[![Cachix Cache](https://img.shields.io/badge/cachix-francynox-blue.svg)](https://francynox.cachix.org)

**My personal [NUR](https://github.com/nix-community/NUR) repository**

Run packages directly from this repository (no cache):

```sh
nix run github:Francynox/nur-packages#some-pakcage
```

Use this repository in `flake.nix`:

```nix
# flake.nix
{
  nixConfig = {
    # substituers will be appended to the default substituters when fetching packages
    extra-substituters = [ "https://francynox.cachix.org" ];
    extra-trusted-public-keys = [ "francynox.cachix.org-1:p66qHTBuD6sRBIggOCoB2iSjmtqLs4a3Fvh3nImvTsg=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur-francynox = {
      url = "github:francynox/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nur-francynox, ... }@inputs: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            # Add packages from this repo
            nur-francynox.packages.${system}.some-package
          ];
        })
      ];
    };
  };
}
```

## Notes

1. Add your packages to the [pkgs](./pkgs) directory and to
   [default.nix](./default.nix)
   * Remember to mark the broken packages as `broken = true;` in the `meta`
     attribute, or travis (and consequently caching) will fail!
   * Library functions, modules and overlays go in the respective directories
2. test build a single package
   ```sh
   nix-build -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz --arg pkgs 'import <nixpkgs> {}' -A some-pakcage
   ```
   or
   ```sh
   nix-build --check -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz --arg pkgs 'import <nixpkgs> {}' -A some-pakcage
   ```
3. test exec
  ```sh
  nix shell .#some-pakcage
  ```

## LICENSE

[MIT](./LICENSE)