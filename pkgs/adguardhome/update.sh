#! /usr/bin/env bash

set -euo pipefail

source update-helper.sh

PKG_NAME="adguardhome"
API_URL="https://api.github.com/repos/AdguardTeam/AdGuardHome/releases?per_page=5"
JQ_FILTER="[.[] | select(.prerelease == true)] | .[0].tag_name | ltrimstr(\"v\")"

version=$(fetch_version_json "$API_URL" "$JQ_FILTER")
run_nix_update "$PKG_NAME" "$version"