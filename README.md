# pipetrace offline release bundle

Public release-only repo. Contains:

- **`pipetrace-0.3.2.tar.xz`** — pipetrace source (`v0.3.2` tag), offline-capable (`third_party/` included)
- **`pipetrace-v0.3.2-windows.zip`** — prebuilt Windows viewer (`pipetrace-view.exe` + `pipetrace.app.json` beside the exe)
- **`pipetrace-0.3.1.*` / `pipetrace-v0.3.1-windows.*`**, **`pipetrace-0.3.0.*` / `pipetrace-v0.3.0-windows.*`**, **`pipetrace-0.2.0.*` / `pipetrace-v0.2.0-windows.*`**, **`pipetrace-0.1.0.*` / `pipetrace-v0.1.0-windows.*`** — previous releases kept for reference
- **`x11-tarballs/`** — X.org sources to bootstrap missing X11 `-dev` headers (no sudo)
- **`scripts/bootstrap_x11_prefix.sh`** — stages headers + linker symlinks into `deps/x11-prefix`

Use when the remote machine has **X11 runtime** (viewer works) but **no `-dev` packages** (build fails on `libXrandr` / RandR headers).

**Windows:** unzip `pipetrace-v0.3.2-windows.zip` and keep `pipetrace.app.json` **beside** `pipetrace-view.exe`. Do **not** double-click the exe alone — open an **analyzed** `.db` (drag-and-drop onto the exe, or Open with). If analyze embedded `app_config_json` into the DB, the sidecar config is optional; otherwise the adjacent `pipetrace.app.json` is required. Fatals write `pipetrace-view.log` next to the exe. Optional checksum: `sha256sum -c pipetrace-v0.3.2-windows.sha256`.

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
sha256sum -c pipetrace-0.3.2.sha256

tar -xJf pipetrace-0.3.2.tar.xz
cd pipetrace-0.3.2

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
sha256sum -c pipetrace-0.3.2.sha256
sha256sum -c pipetrace-v0.3.2-windows.sha256
```

## Contents

| Path | Size (approx) |
|------|----------------|
| `pipetrace-0.3.2.tar.xz` | 4.4 MiB |
| `pipetrace-v0.3.2-windows.zip` | 1.1 MiB |
| `x11-tarballs/` | 4.6 MiB |
| `scripts/bootstrap_x11_prefix.sh` | — |

License: pipetrace is MIT (see `pipetrace-0.3.2/LICENSE` after extract). X.org tarballs are upstream open source.
