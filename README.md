# pipetrace offline release bundle

Public release-only repo. Contains:

- **`pipetrace-0.1.0.tar.xz`** — pipetrace source (v0.1.0 tag), offline-capable (`third_party/` included)
- **`x11-tarballs/`** — X.org sources to bootstrap missing X11 `-dev` headers (no sudo)
- **`scripts/bootstrap_x11_prefix.sh`** — stages headers + linker symlinks into `deps/x11-prefix`

Use when the remote machine has **X11 runtime** (viewer works) but **no `-dev` packages** (build fails on `libXrandr` / RandR headers).

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
sha256sum -c pipetrace-0.1.0.sha256

tar -xJf pipetrace-0.1.0.tar.xz
cd pipetrace-0.1.0

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
sha256sum -c pipetrace-0.1.0.sha256
```

## Contents

| Path | Size (approx) |
|------|----------------|
| `pipetrace-0.1.0.tar.xz` | 4.2 MiB |
| `x11-tarballs/` | 4.6 MiB |
| `scripts/bootstrap_x11_prefix.sh` | — |

License: pipetrace is MIT (see `pipetrace-0.1.0/LICENSE` after extract). X.org tarballs are upstream open source.
