#!/usr/bin/env bash
set -euo pipefail

location=$(curl -fsSI --proto '=https' --tlsv1.2 \
  https://mullvad.net/en/download/browser/linux-x86_64/latest |
  tr -d '\r' | awk 'tolower($1) == "location:" { print $2 }')

latest=$(sed -nE 's|^https://cdn\.mullvad\.net/browser/([0-9]+(\.[0-9]+){0,3})/mullvad-browser-linux-x86_64-\1\.tar\.xz$|\1|p' <<< "$location")
if [[ -z $latest ]]; then
  echo "::error::Unexpected download URL: $location"
  exit 1
fi

current=$(sed -n "s/^\tpkgver = //p" .SRCINFO)
if (( $(vercmp "$latest" "$current") <= 0 )); then
  echo "Up to date: $current"
  exit 0
fi

branch="update/$latest"
if git ls-remote --exit-code --heads origin "$branch" > /dev/null; then
  echo "Branch $branch already exists, skipping"
  exit 0
fi

echo "Updating $current -> $latest"
sed -i -E "s/^pkgver=.*/pkgver=$latest/; s/^pkgrel=.*/pkgrel=1/" PKGBUILD
echo "version=$latest" >> "$GITHUB_OUTPUT"
