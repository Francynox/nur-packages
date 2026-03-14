#! /usr/bin/env bash

set -euo pipefail

PKG_NAME="kea"
PAGE_URL="https://www.isc.org/download/#Kea"
PUP_SELECTOR='div#Kea td.download-version[title*="testing"] .download-version-text text{}'

version=$(fetch_version_html "$PAGE_URL" "$PUP_SELECTOR")
run_nix_update "$PKG_NAME" "$version"