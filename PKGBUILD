# Maintainer: recmanj <recmanj at gmail dot com>

pkgname=mullvad-browser-bin
_pkgname=mullvad-browser
pkgver=16.0
pkgrel=1
pkgdesc='Privacy-focused web browser by Mullvad VPN and the Tor Project (binary release)'
arch=(x86_64 aarch64)
url='https://mullvad.net/en/browser'
license=('MPL-2.0' 'GPL-3.0-or-later' 'OFL-1.1' 'Apache-2.0')
depends=(alsa-lib dbus fontconfig freetype2 gcc-libs glibc gtk3 hicolor-icon-theme libxss)
optdepends=('libpulse: PulseAudio audio support'
	'ffmpeg: H.264 and other media codecs'
	'libnotify: desktop notifications'
	'libva: hardware video decoding'
	'speech-dispatcher: text-to-speech'
	'xdg-desktop-portal: native file dialogs and screen sharing')
provides=("$_pkgname=$pkgver")
conflicts=("$_pkgname")
options=(!strip !debug)
source=("$_pkgname.desktop")
source_x86_64=("https://cdn.mullvad.net/browser/$pkgver/$_pkgname-linux-x86_64-$pkgver.tar.xz"{,.asc})
source_aarch64=("https://cdn.mullvad.net/browser/$pkgver/$_pkgname-linux-aarch64-$pkgver.tar.xz"{,.asc})
# Tor Browser Developers <torbrowser@torproject.org>
# gpg --import keys/pgp/EF6E286DDA85EA2A4BA7DE684E2C6E8793298290.asc
validpgpkeys=('EF6E286DDA85EA2A4BA7DE684E2C6E8793298290')
sha256sums=('5171d67e98b54082a9c60e0aa58c2a3a54c003d563f15ecb9d72f19b29d0f09f')
sha256sums_x86_64=('aa571c6dc00aad214af9a92e414f3a6bd9e12139b4819f5af2f3aaaa3d9f4aa3'
                   'SKIP')
sha256sums_aarch64=('7fda41ffe4c2d732a544f55092ef483128c224a2aa4680d863e793c75e03b3d9'
                    'SKIP')

package() {
	local _dest="$pkgdir/opt/$_pkgname"

	install -dm0755 "$pkgdir/opt"
	cp -a "$srcdir/$_pkgname" "$_dest"

	rm -f "$_dest/start-mullvad-browser.desktop" \
		"$_dest/Browser/start-mullvad-browser.desktop" \
		"$_dest/Browser/execdesktop" \
		"$_dest/Browser/updater" \
		"$_dest/Browser/updater.ini" \
		"$_dest/Browser/update-settings.ini" \
		"$_dest/Browser/precomplete" \
		"$_dest/Browser/removed-files" \
		"$_dest/Browser/icons/updater.png"

	# Upstream ships 0700/0600
	find "$_dest" -type d -exec chmod u=rwx,go=rx,u-s,g-s {} +
	find "$_dest" -type f -perm -u+x -exec chmod 0755 {} +
	find "$_dest" -type f ! -perm -u+x -exec chmod 0644 {} +

	# Profile goes to ~/.mullvad-browser instead of /opt
	touch "$_dest/Browser/is-packaged-app"

	install -Dm0644 /dev/stdin "$_dest/Browser/distribution/policies.json" <<-'JSON'
	{
	  "policies": {
	    "DisableAppUpdate": true
	  }
	}
	JSON

	install -dm0755 "$pkgdir/usr/bin"
	ln -s "/opt/$_pkgname/Browser/start-mullvad-browser" "$pkgdir/usr/bin/$_pkgname"

	install -Dm0644 "$srcdir/$_pkgname.desktop" "$pkgdir/usr/share/applications/$_pkgname.desktop"

	local _size
	for _size in 16 32 48 64 128; do
		install -Dm0644 "$_dest/Browser/browser/chrome/icons/default/default$_size.png" \
			"$pkgdir/usr/share/icons/hicolor/${_size}x${_size}/apps/$_pkgname.png"
	done

	install -Dm0644 -t "$pkgdir/usr/share/licenses/$pkgname/" \
		"$_dest/Browser/MullvadBrowser/Docs/Licenses/"*.txt
}
