#! /usr/bin/env bash

set -euo pipefail

PKG_NAME="bind"
PAGE_URL="https://www.isc.org/download/#BIND"
PUP_SELECTOR='div#BIND td.download-version[title*="testing"] .download-version-text text{}'

version=$(fetch_version_html "$PAGE_URL" "$PUP_SELECTOR")
run_nix_update "$PKG_NAME" "$version"