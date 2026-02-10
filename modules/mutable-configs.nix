{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.francynox.mutable-configs;

  mutableConfigFileOptions = {
    options = {

      source = mkOption {
        type = types.path;
        description = "Path to the configuration file source (Nix store path or local path).";
      };

      mode = mkOption {
        type = types.str;
        default = "0644";
        description = "File mode (e.g. '0644').";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User owner of the file.";
      };

      group = mkOption {
        type = types.str;
        default = "root";
        description = "Group owner of the file.";
      };

      notifyOnUpgrade = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to send a notification if the configuration has changed during an upgrade.";
      };

      stopAutoUpgrade = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to stop the auto-upgrade if the configuration has changed.";
      };

      pathToCheck = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to check against the pristine copy. Defaults to the target file path if not set.";
      };
    };
  };
in
{
  options.services.francynox.mutable-configs = mkOption {
    type = types.attrsOf (types.submodule mutableConfigFileOptions);
    default = { };
    description = ''
      Set of mutable configuration files. Each entry creates:
      1. A writable copy of the source at /etc/<path> (initially copied, never overwritten automatically).
      2. A read-only 'pristine' copy at /etc/<dir>/pristine/<filename>.
      3. A safety check in nixos-upgrade service to prevent overwrites or notify on changes.
    '';
  };

  config = mkIf (cfg != { }) {

    environment.etc = mkMerge (
      mapAttrsToList (name: conf: {
        # Target Configuration File
        "${name}" = {
          inherit (conf)
            source
            mode
            user
            group
            ;
        };

        # Pristine File
        "${toString (dirOf name)}/pristine/${toString (baseNameOf name)}" = {
          inherit (conf) source;
        };
      }) cfg
    );

    # Checks if local files have drifted from the pristine state.
    systemd.services.nixos-upgrade = {
      preStart = ''
        echo "Checking mutable configs for local modifications..."
        EXIT_ON_CHANGE=0

        ${concatStringsSep "\n" (
          mapAttrsToList (name: conf: ''
            TARGET_FILE="/etc/${name}"
            PRISTINE_DIR="$(dirname "$TARGET_FILE")/pristine"
            PRISTINE_FILE="$PRISTINE_DIR/$(basename "$TARGET_FILE")"

            # Determine which file to check against pristine
            CHECK_FILE="${if conf.pathToCheck != null then conf.pathToCheck else "$TARGET_FILE"}"

            if [ -f "$CHECK_FILE" ] && [ -f "$PRISTINE_FILE" ]; then
              if ! cmp -s "$CHECK_FILE" "$PRISTINE_FILE"; then
                echo "  [!] Configuration drift detected: $CHECK_FILE differs from pristine."
                
                ${optionalString conf.notifyOnUpgrade ''
                  # Send notification (wall to all users)
                  echo "Configuration drift detected for $CHECK_FILE during upgrade." | wall -n
                ''}

                ${optionalString conf.stopAutoUpgrade ''
                  echo "  [!!!] CRITICAL: Auto-upgrade stopped due to changes in $CHECK_FILE."
                  EXIT_ON_CHANGE=1
                ''}
              else
                 echo "  [i] $CHECK_FILE matches pristine."
              fi
            else
               echo "  [?] Warning: Could not check $CHECK_FILE or $PRISTINE_FILE (file missing)."
            fi
          '') cfg
        )}

        if [ "$EXIT_ON_CHANGE" -eq 1 ]; then
          echo "Aborting auto-upgrade."
          exit 1
        fi
      '';
    };
  };
}
