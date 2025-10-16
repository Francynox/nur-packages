{
  # Add your NixOS modules here
  #
  # my-module = ./my-module;
  kea = import ./kea.nix;
  bind = import ./bind.nix;
  adguardhome = import ./adguardhome.nix;
  unbound = import ./unbound.nix;
}
