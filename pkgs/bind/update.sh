#! /usr/bin/env bash

set -euo pipefail

source update-helper.sh

PKG_NAME="bind"
PAGE_URL="https://www.isc.org/download/#BIND"
PUP_SELECTOR='div#BIND :parent-of(td:contains("Development")) td:first-child text{}'

version=$(fetch_version_html "$PAGE_URL" "$PUP_SELECTOR")
run_nix_update "$PKG_NAME" "$version"