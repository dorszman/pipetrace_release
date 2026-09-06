# pipetrace offline release bundle

**Windows debug (v0.3.6+):** unzip `pipetrace-v0.3.6-windows.zip` to a writable folder and double-click `run_debug.bat` (includes `tiny_analyzed.db`). Send Desktop `pipetrace-view*.log` copies + exit code back. See `README_WINDOWS_DEBUG.txt`.

Public release-only repo. Contains:

- **`pipetrace-0.3.4.tar.xz`** — pipetrace source (`v0.3.4` tag), offline-capable (`third_party/` included)
- **`pipetrace-v0.3.4-windows.zip`** — prebuilt Windows viewer (`pipetrace-view.exe` + `LICENSE` only; **no** `pipetrace.app.json`)
- **`tiny_analyzed.db`** — tiny analyzed store with embedded `app_config_json` for Windows smoke / first open
- **`pipetrace-0.3.3.*` / `pipetrace-v0.3.3-windows.*`**, **`pipetrace-0.3.2.*` / …**, **`pipetrace-0.3.1.*` / …**, **`pipetrace-0.3.0.*` / …**, **`pipetrace-0.2.0.*` / …**, **`pipetrace-0.1.0.*` / …** — previous releases kept for reference
- **`x11-tarballs/`** — X.org sources to bootstrap missing X11 `-dev` headers (no sudo)
- **`scripts/bootstrap_x11_prefix.sh`** — stages headers + linker symlinks into `deps/x11-prefix`

Use when the remote machine has **X11 runtime** (viewer works) but **no `-dev` packages** (build fails on `libXrandr` / RandR headers).

**Windows:** unzip `pipetrace-v0.3.4-windows.zip`. Open an **analyzed** `.db` (drag-and-drop onto the exe, or Open with) — config comes from the DB `app_config_json` embed. There is **no** `pipetrace.app.json` in the zip. For a quick smoke test, open `tiny_analyzed.db` from this repo. Do **not** double-click the exe alone. Fatals and hard crashes write `pipetrace-view.log` next to the exe (startup breadcrumbs + exception codes). Optional checksum: `sha256sum -c pipetrace-v0.3.4-windows.sha256`.

**TEMPORARY Windows silent-exit debug:** see [`WINDOWS_DEBUG_HANDOFF.md`](WINDOWS_DEBUG_HANDOFF.md) (v0.2.0 works / v0.3.4+ exits; delete after fix).

**Step-by-step Linux/offline build commands:** see [`OFFLINE_BUILD.md`](OFFLINE_BUILD.md).

## Clone (HTTP)

```bash
git clone http://github.com/dorszman/pipetrace_release.git
cd pipetrace_release
```

## Build pipetrace + viewer (offline after clone)

```bash
cd pipetrace_release

# optional: verify tarballs
sha256sum -c x11-tarballs.sha256
sha256sum -c pipetrace-0.3.4.sha256

tar -xJf pipetrace-0.3.4.tar.xz
cd pipetrace-0.3.4

# Stage local X11 prefix (no network; uses ../x11-tarballs)
../scripts/bootstrap_x11_prefix.sh --tarball-dir ../x11-tarballs

# build (auto-detects deps/x11-prefix if present)
./build.sh
```

Binaries land in `build/`:

- `pipetrace-view` — GUI
- `pipetrace-linx` — orchestrator
- `pipetrace-linx-parser`, `pipetrace-linx-analyze`, …

## What bootstrap does

1. Installs X11 **headers** from `x11-tarballs/` into `deps/x11-prefix/include/`
2. Creates `libXrandr.so` → system `libXrandr.so.*` symlinks (and Xinerama, Xcursor, Xi, …)
3. Writes minimal `.pc` files for CMake / GLFW

Requires system **runtime** libs (`libxrandr2`, `libx11-6`, …) — usually already present if X11 works.

## System packages still needed (no sudo alternative)

- C++ compiler (`g++`)
- CMake 3.20+
- OpenGL dev headers (`libgl-dev` or `libgl1-mesa-dev`) — if missing, GUI may not build; CLI tools still build with `-DPIPetrace_BUILD_GUI=OFF`

## Verify checksums

```bash
sha256sum -c x11-tarballs.sha256
sha256sum -c pipetrace-0.3.4.sha256
sha256sum -c pipetrace-v0.3.4-windows.sha256
sha256sum -c tiny_analyzed.db.sha256
```

## Contents

| Path | Size (approx) |
|------|----------------|
| `pipetrace-0.3.4.tar.xz` | 4.4 MiB |
| `pipetrace-v0.3.4-windows.zip` | 1.1 MiB |
| `tiny_analyzed.db` | 88 KiB |
| `x11-tarballs/` | 4.6 MiB |
| `scripts/bootstrap_x11_prefix.sh` | — |

License: pipetrace is MIT (see `pipetrace-0.3.4/LICENSE` after extract). X.org tarballs are upstream open source.
