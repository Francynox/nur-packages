# tests/_modules.nix
{ lib, ... }:
{
  imports = lib.attrValues (import ../modules);
}
