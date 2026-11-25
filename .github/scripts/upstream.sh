#!/usr/bin/env bash
# The checksums come from the sha256sums file on the GitHub release, which is
# signed with the same key as the tarballs, in keys/pgp.
#
#   upstream.sh latest         version the download page redirects to
#   upstream.sh sums VERSION   "<arch> <sha256> SKIP" per arch, the SKIP being
#                              for the tarball's .asc
set -euo pipefail

arches=(x86_64 aarch64)
keys_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../keys/pgp" && pwd)

die() { echo "::error::$*" >&2; exit 1; }
fetch() { curl -fsSL --proto '=https' --tlsv1.2 --retry 3 -o "$2" "$1"; }

case ${1:-} in
  latest)
    location=$(curl -fsSI --proto '=https' --tlsv1.2 --retry 3 \
      https://mullvad.net/en/download/browser/linux-x86_64/latest |
      tr -d '\r' | awk 'tolower($1) == "location:" { print $2 }')
    sed -nE 's|^https://cdn\.mullvad\.net/browser/([0-9]+(\.[0-9]+){0,3})/mullvad-browser-linux-x86_64-\1\.tar\.xz$|\1|p' \
      <<< "$location" | grep . || die "Unexpected download URL: $location"
    ;;
  sums)
    version=${2:?usage: upstream.sh sums VERSION}
    [[ $version =~ ^[0-9]+(\.[0-9]+)*$ ]] || die "Invalid version: $version"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    export GNUPGHOME="$tmp/gnupg"
    mkdir -m 0700 "$GNUPGHOME"

    cat "$keys_dir"/*.asc | gpg --batch --dearmor > "$tmp/keyring.gpg"
    url=https://github.com/mullvad/mullvad-browser/releases/download/$version/sha256sums-signed-build.txt
    fetch "$url" "$tmp/sums"
    fetch "$url.asc" "$tmp/sums.asc"
    gpgv --keyring "$tmp/keyring.gpg" "$tmp/sums.asc" "$tmp/sums" 2> "$tmp/gpgv.log" ||
      { cat "$tmp/gpgv.log" >&2; die 'sha256sums signature verification failed'; }

    for a in "${arches[@]}"; do
      sum=$(awk -v f="mullvad-browser-linux-$a-$version.tar.xz" '$2 == f { print $1 }' "$tmp/sums")
      [[ $sum =~ ^[0-9a-f]{64}$ ]] || die "No checksum for $a in sha256sums"
      echo "$a $sum SKIP"
    done
    ;;
  *)
    die 'usage: upstream.sh latest | sums VERSION'
    ;;
esac
