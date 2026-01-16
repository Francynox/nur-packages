#! /usr/bin/env bash

set -euo pipefail

PKG_NAME="proxmox-vma"

# Update QEMU Version
API_URL_QEMU="https://api.github.com/repos/proxmox/mirror_qemu/tags"
JQ_FILTER_QEMU=".[0].name | ltrimstr(\"v\")"

version=$(fetch_version_json "$API_URL_QEMU" "$JQ_FILTER_QEMU")
nix-update proxmox-vma --version "$version"


# Update Patch Source
API_URL_VMA="https://api.github.com/repos/proxmox/pve-qemu/commits/master"
JQ_FILTER_VMA=".sha"

rev=$(fetch_version_json "$API_URL_VMA" "$JQ_FILTER_VMA")
nix-update proxmox-vma.proxmoxPatchSrc --version "$rev"
