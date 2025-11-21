#! /usr/bin/env bash

set -euo pipefail

PKG_NAME="unbound"
API_URL="https://api.github.com/repos/NLnetLabs/unbound/releases?per_page=5"
JQ_FILTER=".[0].tag_name | ltrimstr(\"release-\")"

version=$(fetch_version_json "$API_URL" "$JQ_FILTER")
run_nix_update "$PKG_NAME" "$version"