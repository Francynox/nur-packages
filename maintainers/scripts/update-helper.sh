#! /usr/bin/env bash

validate_version() {
  local version="$1"
  local source="$2"
  if [[ -z "$version" || "$version" == "null" ]]; then
    echo "Error: Unable to retrieve version from $source" >&2
    exit 1
  fi
}

# Function to retrieve a version from a JSON URL (API GitHub)
# Example: fetch_version_json <url> <filtro_jq>
fetch_version_json() {
  local url="$1"
  local jq_filter="$2"
  local version

  echo "Fetching version from $url..." >&2
  version=$(curl -s --fail --connect-timeout 10 --max-time 30 "$url" | jq -r "$jq_filter")

  validate_version "$version" "$url (jq filter: $jq_filter)"
  echo "Extracted version: $version" >&2

  echo "$version"
}

# Function to retrieve a version from HTML
# Example: fetch_version_html <url> <selettore_pup>
fetch_version_html() {
  local url="$1"
  local pup_selector="$2"
  local version

  echo "Fetching version from $url..." >&2
  version=$(curl -s --fail --connect-timeout 10 --max-time 30 "$url" | pup "$pup_selector" | xargs)

  validate_version "$version" "$url (pup selector: $pup_selector)"
  echo "Extracted version: $version" >&2

  echo "$version"
}

run_nix_update() {
  local pkg_name="$1"
  local version="$2"

  local current_version
  current_version=$(nix eval -f . "${pkg_name}.version" --raw 2>/dev/null || echo "")
  if [[ "$current_version" == "$version" ]]; then
    echo "'$pkg_name' is already at the latest version ($version). No update needed." >&2
    exit 0
  fi

  echo "Running nix-update for '$pkg_name' to version '$version'..." >&2

  nix-update "$pkg_name" --version "$version"

  echo "'$pkg_name' updated successfully to version $version." >&2
}