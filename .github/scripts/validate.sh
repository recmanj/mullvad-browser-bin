#!/usr/bin/env bash
# UPDATE_SUMS=1 regenerates checksums and .SRCINFO first.
set -euo pipefail

pacman -Syu --noconfirm --needed namcap shellcheck pacman-contrib

id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
chown -R builder: .

sudo -u builder UPDATE_SUMS="${UPDATE_SUMS:-0}" bash -euo pipefail <<'EOF'
gpg --batch --import keys/pgp/*.asc

if [[ $UPDATE_SUMS == 1 ]]; then
  echo '::group::Update checksums and .SRCINFO'
  updpkgsums
  makepkg --printsrcinfo > .SRCINFO
  echo '::endgroup::'
fi

echo '::group::.SRCINFO is up to date'
diff -u .SRCINFO <(makepkg --printsrcinfo)
echo '::endgroup::'

echo '::group::shellcheck'
shellcheck --shell=bash --exclude=SC2034,SC2154 PKGBUILD
shellcheck .github/scripts/*.sh
echo '::endgroup::'

# --verifysource only checks CARCH
for arch in $(source PKGBUILD; echo "${arch[@]}"); do
  echo "::group::Checksums and signatures ($arch)"
  sed "s/^CARCH=.*/CARCH=\"$arch\"/" /etc/makepkg.conf > "/tmp/makepkg-$arch.conf"
  makepkg --config "/tmp/makepkg-$arch.conf" --verifysource --noconfirm
  echo '::endgroup::'
done

echo '::group::namcap PKGBUILD'
namcap PKGBUILD | tee /tmp/namcap.txt
echo '::endgroup::'

echo '::group::Build'
PKGEXT=.pkg.tar makepkg --syncdeps --cleanbuild --noconfirm
echo '::endgroup::'

echo '::group::namcap package'
namcap ./*.pkg.tar | tee -a /tmp/namcap.txt
echo '::endgroup::'

if grep -q ' E: ' /tmp/namcap.txt; then
  echo '::error::namcap reported errors'
  exit 1
fi
EOF
