{
  pkgs ? import <nixpkgs> { },
  package ? "",
}:

let
  nur-pkgs = import ../.. { pkgs = pkgs; };

  helperDir = ./.;

  pkg =
    if builtins.hasAttr package nur-pkgs then
      nur-pkgs.${package}
    else
      throw "Package '${package}' not found in NUR repository.";

  updateScriptPath = pkgs.lib.attrByPath [ "passthru" "updateScript" ] "" pkg;

  updateScript = pkgs.writeShellScript "updater" ''
    #!${pkgs.stdenv.shell}
    set -euo pipefail
     
    function log_return {
      if [[ $1 -eq 0 ]]; then
        echo "--------------------------------------------------------"
        echo "✅ SUCCESS: Update script finished."
        echo "--------------------------------------------------------"
      else
        echo "--------------------------------------------------------"
        echo "❌ ERROR: Update script failed with exit code $1."
        echo "--------------------------------------------------------"
      fi

      exit "$1"
    }

    function run_and_capture_exit {
      echo "Executing command: $*" >&2

      $@ >&2
      echo $?
    }

    echo "--- Centralized NUR update script started ---"
    echo "Package to update: ${package}"

    # Check if an update script is defined for the package
    if [ -n "${updateScriptPath}" ]; then
      echo "Found update script at: ${updateScriptPath}"
      echo "Executing update script..."

      export PATH="${helperDir}:$PATH"

      return_code=$(run_and_capture_exit bash ${updateScriptPath})
      log_return $return_code 
    else
      echo "Warning: No 'passthru.updateScript' defined for package '${package}'. Executing default nix-update."

      return_code=$(run_and_capture_exit nix-update ${package})
      log_return $return_code
    fi
  '';

in
pkgs.stdenv.mkDerivation {
  name = "nur-updater-env";

  nativeBuildInputs = [
    pkgs.nix-update
    pkgs.curl
    pkgs.pup
    pkgs.jq
  ];

  shellHook = ''
    unset shellHook
    exec ${updateScript}
  '';
}
