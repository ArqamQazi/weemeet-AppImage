#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -S --needed --noconfirm \
	base-devel git wget patchelf \
	alsa-lib libpulse openssl libxinerama libxcomposite libxdamage libxrandr libyuv

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
if [ -n "${CI:-}" ] || [ "${USE_DEBLOAT:-0}" = "1" ]; then
	# Don't install system qt5-base, wemeet bundles its own Qt
	get-debloated-pkgs --add-common --prefer-nano ! qt5-base
fi

echo "Building and installing wemeet from AUR..."
echo "---------------------------------------------------------------"
MAKE_AUR_PKG="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/make-aur-package.sh"
if ! command -v make-aur-package >/dev/null 2>&1; then
	wget --retry-connrefused --tries=10 -qO /tmp/make-aur-package "$MAKE_AUR_PKG"
	chmod +x /tmp/make-aur-package
	MAKE_AUR_PKG_BIN="/tmp/make-aur-package"
else
	MAKE_AUR_PKG_BIN="make-aur-package"
fi

# Clean up any leftover directory before build
rm -rf ./wemeet-bin

# If a local deb package exists (e.g. to bypass regional/ISP blocks on updatecdn.meeting.qq.com),
# copy it into the build directory before makepkg runs so makepkg reuses it.
export PRE_BUILD_CMDS='for f in ../*.deb ../wemeet*.deb ../*TencentMeeting*.deb /tmp/*.deb /tmp/wemeet*.deb /tmp/*TencentMeeting*.deb; do [ -f "$f" ] && echo "Using local deb: $f" && cp -fv "$f" ./wemeet-3.26.10.401-'"$ARCH"'.deb && break; done || true'

$MAKE_AUR_PKG_BIN wemeet-bin

# Clean up build directory after successful install
rm -rf ./wemeet-bin
