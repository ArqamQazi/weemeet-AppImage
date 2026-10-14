#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wemeet-bin 2>/dev/null | awk '{print $2; exit}')
if [ -z "${VERSION:-}" ] && [ -f ~/version ]; then
	VERSION=$(cat ~/version)
fi
VERSION="${VERSION:-3.26.10.401}"
export ARCH VERSION
export OUTPATH=./dist

# Ignore inherited APPDIR from parent AppImage mounts if any
case "${APPDIR:-}" in
	/tmp/.mount_*) unset APPDIR ;;
esac

export DESKTOP=/usr/share/applications/wemeetapp.desktop
if [ -f /usr/share/icons/hicolor/scalable/apps/wemeet.svg ]; then
	export ICON=/usr/share/icons/hicolor/scalable/apps/wemeet.svg
elif [ -f /usr/share/icons/hicolor/256x256/apps/wemeetapp.png ]; then
	export ICON=/usr/share/icons/hicolor/256x256/apps/wemeetapp.png
else
	export ICON=/usr/share/icons/hicolor/scalable/apps/wemeet.svg
fi

export ADD_HOOKS="self-updater.hook:fix-namespaces.hook"

if [ -n "${GITHUB_REPOSITORY:-}" ]; then
	export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
fi

if [ -z "${CI:-}" ]; then
	export DWARFS_COMP="${DWARFS_COMP:-zstd:level=1}"
	export NO_STRIP="${NO_STRIP:-1}"
	export STRACE_TIME="${STRACE_TIME:-1}"
fi

export MAIN_BIN=wemeetapp
export STARTUPWMCLASS=wemeetapp
export DEPLOY_PIPEWIRE=1
export DEPLOY_PULSE=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

# Wemeet bundles its own private Qt and QtWebEngine (like Viber-AppImage-Enhanced)
export DEPLOY_QT=0
export DEPLOY_QML=0
export DEPLOY_QT_WEB_ENGINE=0

# Allow ldd to resolve wemeet's private libraries during deployment
export LD_LIBRARY_PATH="/usr/lib/wemeet:${LD_LIBRARY_PATH:-}"

# Map hardcoded wemeet library and binary directories
export PATH_MAPPING='
	/usr/lib/wemeet:${SHARUN_DIR}/lib/wemeet
	/opt/wemeet/bin:${SHARUN_DIR}/bin
'

# Pre-stage wemeet binary, modules, and configs before deployment
mkdir -p ./AppDir/bin
if [ -d /opt/wemeet/bin ]; then
	cp -r /opt/wemeet/bin/* ./AppDir/bin/
fi

# Pre-stage runtime hook to configure styling, Wayland/X11 quirks, and preloads
cat << 'EOF' > ./AppDir/bin/09-wemeet-env.hook
# Wemeet runtime environment setup
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_STYLE_OVERRIDE=fusion
export IBUS_USE_PORTAL=1

# Allow LD_PRELOAD inside sharun
export SHARUN_ALLOW_LD_PRELOAD=1

# Force X11 / XWayland mode (Wemeet has known crashes under native Wayland)
export QT_QPA_PLATFORM=xcb
export XDG_SESSION_TYPE=x11
unset WAYLAND_DISPLAY
export WEMEET_XWAYLAND=1

# Preload wemeet wrapper shim if present
if [ -f "$APPDIR/lib/wemeet/libwemeetwrap.so" ]; then
	export LD_PRELOAD="${LD_PRELOAD:+$LD_PRELOAD:}$APPDIR/lib/wemeet/libwemeetwrap.so"
fi
EOF
chmod +x ./AppDir/bin/09-wemeet-env.hook

# Preload wrapper shim directly in sharun-preload if built
mkdir -p ./AppDir/lib/sharun-preload
if [ -f /usr/lib/wemeet/libwemeetwrap.so ]; then
	cp -fv /usr/lib/wemeet/libwemeetwrap.so ./AppDir/lib/sharun-preload/
fi

# Dynamically collect all shared libraries inside ./AppDir/bin (modules, etc.)
MODULE_LIBS=""
if [ -d ./AppDir/bin/modules ]; then
	MODULE_LIBS=$(find ./AppDir/bin/modules -type f -name '*.so*' 2>/dev/null || true)
fi

# Deploy dependencies and libraries
# Note: /usr/lib/wemeet includes Wemeet's bundled Qt plugins (e.g. plugins/platforms/libqxcb.so)
quick-sharun \
	./AppDir/bin/wemeetapp \
	$MODULE_LIBS \
	/usr/lib/wemeet \
	/usr/lib/libyuv.so* \
	/usr/lib/libssl.so* \
	/usr/lib/libcrypto.so*

# Ensure configs and modules are accessible relative to shared/bin as well
mkdir -p ./AppDir/shared/bin
for item in modules qt.conf xcast.conf raw; do
	if [ -e "./AppDir/bin/$item" ] && [ ! -e "./AppDir/shared/bin/$item" ]; then
		ln -sf "../../bin/$item" "./AppDir/shared/bin/$item"
	fi
done

# Ensure binary symlinks and desktop Exec match MAIN_BIN
ln -sf wemeetapp ./AppDir/bin/wemeet 2>/dev/null || :
ln -sf wemeetapp ./AppDir/shared/bin/wemeet 2>/dev/null || :
sed -i 's|^Exec=wemeet|Exec=wemeetapp|g' ./AppDir/wemeetapp.desktop 2>/dev/null || :

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the AppImage (fallback to extract-and-run in CI environments without unprivileged userns/FUSE)
if [ -n "${CI:-}" ] || [ "${RUN_TEST:-0}" = "1" ]; then
	export APPIMAGE_EXTRACT_AND_RUN=1
	quick-sharun --simple-test ./dist/*.AppImage
fi
