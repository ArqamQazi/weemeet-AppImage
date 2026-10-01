#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q PACKAGENAME 2>/dev/null | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export OUTPATH=./dist
export ICON=PATH_OR_URL_TO_ICON
export DESKTOP=PATH_OR_URL_TO_DESKTOP_ENTRY

if [ -n "${GITHUB_REPOSITORY:-}" ]; then
	export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
	export ADD_HOOKS="${ADD_HOOKS:-self-updater.hook}"
fi

if [ -z "${CI:-}" ]; then
	export DWARFS_COMP="${DWARFS_COMP:-zstd:level=1}"
	export NO_STRIP="${NO_STRIP:-1}"
	export STRACE_TIME="${STRACE_TIME:-1}"
fi

# Deploy dependencies
quick-sharun /PATH/TO/BINARY_AND_LIBRARIES_HERE

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
if [ -n "${CI:-}" ] || [ "${RUN_TEST:-0}" = "1" ]; then
	quick-sharun --test ./dist/*.AppImage
fi
