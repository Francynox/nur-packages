{
  pkgs,
  modules,
  ...
}:
{
  kea = import ./kea.nix { inherit pkgs modules; };
  bind = import ./bind.nix { inherit pkgs modules; };
  adguardhome = import ./adguardhome.nix { inherit pkgs modules; };
  unbound = import ./unbound.nix { inherit pkgs modules; };
}
