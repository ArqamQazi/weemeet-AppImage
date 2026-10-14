<div align="center">

# wemeet-AppImage 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/wemeet-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/wemeet-AppImage/releases/latest)
[![CI Build Status](https://github.com/pkgforge-dev/wemeet-AppImage/actions/workflows/appimage.yml/badge.svg)](https://github.com/pkgforge-dev/wemeet-AppImage/releases/latest)
[![Latest Stable Release](https://img.shields.io/github/v/release/pkgforge-dev/wemeet-AppImage)](https://github.com/pkgforge-dev/wemeet-AppImage/releases/latest)

<p align="center">
  <img src="https://github.com/pkgforge-dev.png" width="128" />
</p>


| Latest Stable Release | Upstream URL |
| :---: | :---: |
| [Click here](https://github.com/pkgforge-dev/wemeet-AppImage/releases/latest) | [Click here](https://meeting.tencent.com) |

</div>

---

AppImage for **Tencent Meeting (腾讯会议 / wemeet)** made using [quick-sharun](https://github.com/pkgforge-dev/Anylinux-AppImages/blob/main/useful-tools/quick-sharun.sh), which turns binaries into portable packages reliably without using containers or root privileges.

**This AppImage bundles all dependencies and works on any Linux distribution, including old and musl-based distributions.**

- **No FUSE Required**: Runs using fallback unprivileged namespaces or extraction thanks to [uruntime](https://github.com/VHSgunzo/uruntime).
- **Self-Updater**: Automatically checks for updates unless an AppImage manager ([am](https://github.com/ivan-hc/AM), [soar](https://github.com/pkgforge/soar), or [dbin](https://github.com/xplshn/dbin)) is installed.
- **Audio & Wayland Compatibility**: Includes the `wrap.c` preload shim to resolve OpenSSL 3 symbols, PulseAudio hardware sink detection on PipeWire/Pulse, and X11/XWayland session quirks.

---

More at: [AnyLinux-AppImages](https://pkgforge-dev.github.io/Anylinux-AppImages/)
