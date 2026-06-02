{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.services.francynox.lxc-wipe-on-boot;

  initWipeScript = pkgs.replaceVarsWith {
    src = ./init-wipe.sh;
    isExecutable = true;
    replacements = {
      inherit (pkgs) runtimeShell;
      path = lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
      ];
      inherit (config.networking) hostName;
    };
  };

  initWrapper = pkgs.writeScript "init-wrapper" ''
    #!${pkgs.runtimeShell}
    ${initWipeScript}
    exec ${config.system.build.toplevel}/init "$@"
  '';

  installScriptBuilder = pkgs.replaceVarsWith {
    src = ./install-bootloader.sh;
    isExecutable = true;
    replacements = {
      inherit (pkgs) runtimeShell;
      path = lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnused
        pkgs.gnugrep
      ];
      initWipe = "${initWipeScript}";
    };
  };
in
{
  options.services.francynox.lxc-wipe-on-boot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Proxmox LXC impermanence (root wipe-on-boot wrapper).";
    };
  };

  config = lib.mkIf cfg.enable {
    system.build.init-wipe = initWipeScript;

    system.build.tarball = lib.mkForce (
      pkgs.callPackage "${modulesPath}/../lib/make-system-tarball.nix" {
        fileName = config.image.baseName;
        storeContents = [
          {
            object = config.system.build.toplevel;
            symlink = "none";
          }
        ];

        contents = [
          {
            source = initWrapper;
            target = "sbin/init";
            mode = "0755";
          }
        ];
      }
    );

    system.build.installBootLoader = lib.mkForce installScriptBuilder;
  };
}
