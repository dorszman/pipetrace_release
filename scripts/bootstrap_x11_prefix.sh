#!/usr/bin/env bash
# Build / stage X11 client headers+libs into a user prefix (no sudo).
#
# GLFW needs X11 development pieces (Xrandr, Xinerama, Xcursor, Xi, …).
# Without apt -dev packages, CMake fails with "RandR headers not found".
#
# Default mode (recommended): install headers from source tarballs and create
# libFoo.so -> system libFoo.so.N symlinks under deps/x11-prefix.
#
# Full compile mode: --from-source (needs network or --tarball-dir, plus
# meson/ninja or autoconf; slower and heavier).
#
# Usage:
#   ./scripts/bootstrap_x11_prefix.sh
#   ./scripts/bootstrap_x11_prefix.sh --tarball-dir /path/to/x11-tarballs
#   ./scripts/bootstrap_x11_prefix.sh --from-source
#   cmake -S . -B build -DCMAKE_PREFIX_PATH=$PWD/deps/x11-prefix ...
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PIPetrace_X11_PREFIX:-$ROOT/deps/x11-prefix}"
SRC_CACHE="${PIPetrace_X11_TARBALL_DIR:-$ROOT/deps/x11-src}"
FROM_SOURCE=0
TARBALL_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-source) FROM_SOURCE=1; shift ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    --tarball-dir) TARBALL_DIR="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$TARBALL_DIR" ]]; then
  SRC_CACHE="$TARBALL_DIR"
fi

mkdir -p "$PREFIX"/{include,lib,lib/pkgconfig} "$SRC_CACHE" "$ROOT/deps/x11-build"

have_header() {
  local rel="$1"
  [[ -f "/usr/include/$rel" ]] || [[ -f "/usr/local/include/$rel" ]] || [[ -f "$PREFIX/include/$rel" ]]
}

find_soname() {
  # find_soname libXrandr  -> prints path to libXrandr.so.*
  local base="$1"
  local f
  for f in \
    /usr/lib/x86_64-linux-gnu/${base}.so \
    /usr/lib64/${base}.so \
    /usr/lib/${base}.so \
    /usr/lib/x86_64-linux-gnu/${base}.so.* \
    /usr/lib64/${base}.so.* \
    /usr/lib/${base}.so.*; do
    if [[ -e "$f" ]]; then
      readlink -f "$f"
      return 0
    fi
  done
  return 1
}

link_lib() {
  local name="$1"   # e.g. Xrandr -> libXrandr
  local lib="lib${name}"
  local dest="$PREFIX/lib/${lib}.so"
  if [[ -e "$dest" ]]; then
    return 0
  fi
  local src
  if ! src="$(find_soname "$lib")"; then
    echo "WARNING: system ${lib}.so* not found — install runtime package or use --from-source" >&2
    return 1
  fi
  ln -sfn "$src" "$dest"
  echo "  link ${lib}.so -> $src"
}

fetch() {
  # fetch URL outfile — uses cache; fails clearly if offline and missing
  local url="$1" out="$2"
  if [[ -f "$out" ]]; then
    return 0
  fi
  echo "  download $(basename "$out")"
  if ! curl -fsSL "$url" -o "$out"; then
    echo "ERROR: failed to download $url" >&2
    echo "  Copy the tarball to $SRC_CACHE/$(basename "$out") on an online machine, then re-run with --tarball-dir." >&2
    exit 1
  fi
}

extract_into() {
  local tar="$1" dest="$2"
  mkdir -p "$dest"
  tar -xf "$tar" -C "$dest" --strip-components=1
}

write_pc() {
  local name="$1" version="$2" requires="${3:-}" libs="${4:--l$name}"
  local pc="$PREFIX/lib/pkgconfig/${name}.pc"
  cat >"$pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: $name
Description: $name (pipetrace local prefix)
Version: $version
Requires: $requires
Libs: -L\${libdir} $libs
Cflags: -I\${includedir}
EOF
}

echo "X11 prefix: $PREFIX"
echo "Tarball cache: $SRC_CACHE"

# --- Headers: always stage xorgproto + per-lib public headers into PREFIX ---
XORGPROTO_VER="2024.1"
LIBXRANDR_VER="1.5.4"
LIBXINERAMA_VER="1.1.5"
LIBXCURSOR_VER="1.2.3"
LIBXI_VER="1.8.2"
LIBXFIXES_VER="6.0.1"
LIBXRENDER_VER="0.9.12"
LIBXEXT_VER="1.3.6"
LIBX11_VER="1.8.10"

need_any_headers=0
for h in \
  X11/extensions/Xrandr.h \
  X11/extensions/Xinerama.h \
  X11/Xcursor/Xcursor.h \
  X11/extensions/XInput2.h \
  X11/extensions/shape.h \
  X11/extensions/Xrender.h \
  X11/extensions/Xfixes.h; do
  if ! have_header "$h"; then
    need_any_headers=1
    echo "missing system header: $h"
  fi
done

stage_lib_headers() {
  local name="$1" ver="$2" url="$3"
  local tar="$SRC_CACHE/${name}-${ver}.tar.xz"
  local build="$ROOT/deps/x11-build/${name}-${ver}"
  fetch "$url" "$tar"
  rm -rf "$build"
  extract_into "$tar" "$build"
  if [[ -d "$build/include/X11" ]]; then
    mkdir -p "$PREFIX/include"
    cp -a "$build/include/X11/." "$PREFIX/include/X11/"
  fi
}

if [[ "$need_any_headers" -eq 1 ]] || [[ ! -f "$PREFIX/include/X11/extensions/randr.h" ]]; then
  echo "Staging X11 headers into prefix..."
  mkdir -p "$PREFIX/include/X11"
  stage_lib_headers xorgproto "$XORGPROTO_VER" \
    "https://www.x.org/releases/individual/proto/xorgproto-${XORGPROTO_VER}.tar.xz"
  stage_lib_headers libXrandr "$LIBXRANDR_VER" \
    "https://www.x.org/releases/individual/lib/libXrandr-${LIBXRANDR_VER}.tar.xz"
  stage_lib_headers libXinerama "$LIBXINERAMA_VER" \
    "https://www.x.org/releases/individual/lib/libXinerama-${LIBXINERAMA_VER}.tar.xz"
  stage_lib_headers libXcursor "$LIBXCURSOR_VER" \
    "https://www.x.org/releases/individual/lib/libXcursor-${LIBXCURSOR_VER}.tar.xz"
  stage_lib_headers libXi "$LIBXI_VER" \
    "https://www.x.org/releases/individual/lib/libXi-${LIBXI_VER}.tar.xz"
  stage_lib_headers libXfixes "$LIBXFIXES_VER" \
    "https://www.x.org/releases/individual/lib/libXfixes-${LIBXFIXES_VER}.tar.xz"
  stage_lib_headers libXrender "$LIBXRENDER_VER" \
    "https://www.x.org/releases/individual/lib/libXrender-${LIBXRENDER_VER}.tar.xz"
  stage_lib_headers libXext "$LIBXEXT_VER" \
    "https://www.x.org/releases/individual/lib/libXext-${LIBXEXT_VER}.tar.xz"
  stage_lib_headers libX11 "$LIBX11_VER" \
    "https://www.x.org/releases/individual/lib/libX11-${LIBX11_VER}.tar.xz"
else
  echo "System already has required X11 extension headers."
fi

echo "Creating linker symlinks to system shared libraries..."
failed=0
for name in X11 Xext Xrender Xfixes Xrandr Xinerama Xcursor Xi; do
  link_lib "$name" || failed=1
done
if [[ "$failed" -eq 1 && "$FROM_SOURCE" -eq 0 ]]; then
  echo "" >&2
  echo "Some system .so files were missing. Options:" >&2
  echo "  1) Ask admin to install runtime packages (libxrandr2 libxinerama1 libxcursor1 libxi6 …)" >&2
  echo "  2) Re-run with --from-source (builds libs into $PREFIX)" >&2
  exit 1
fi

# pkg-config files so CMake FindX11 / GLFW can locate the prefix
write_pc xrandr "$LIBXRANDR_VER" "x11 xext xrender" "-lXrandr"
write_pc xinerama "$LIBXINERAMA_VER" "x11 xext" "-lXinerama"
write_pc xcursor "$LIBXCURSOR_VER" "x11 xrender xfixes" "-lXcursor"
write_pc xi "$LIBXI_VER" "x11 xext" "-lXi"
write_pc xfixes "$LIBXFIXES_VER" "x11" "-lXfixes"
write_pc xrender "$LIBXRENDER_VER" "x11" "-lXrender"
write_pc xext "$LIBXEXT_VER" "x11" "-lXext"
write_pc x11 "1.8" "" "-lX11"

build_one_meson() {
  local name="$1" ver="$2" url="$3"
  local tar="$SRC_CACHE/${name}-${ver}.tar.xz"
  local build="$ROOT/deps/x11-build/${name}-${ver}"
  fetch "$url" "$tar"
  rm -rf "$build"
  extract_into "$tar" "$build"
  echo "  meson build $name-$ver"
  if ! command -v meson >/dev/null || ! command -v ninja >/dev/null; then
    echo "ERROR: --from-source needs meson and ninja (pip install --user meson ninja)." >&2
    exit 1
  fi
  (
    cd "$build"
    meson setup builddir --prefix="$PREFIX" --libdir=lib \
      -Ddocumentation=false 2>/dev/null \
      || meson setup builddir --prefix="$PREFIX" --libdir=lib
    ninja -C builddir
    ninja -C builddir install
  )
}

if [[ "$FROM_SOURCE" -eq 1 ]]; then
  echo "Building X11 client libraries from source into $PREFIX ..."
  export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
  export PATH="${HOME}/.local/bin:${PATH}"
  build_one_meson xorgproto "$XORGPROTO_VER" \
    "https://www.x.org/releases/individual/proto/xorgproto-${XORGPROTO_VER}.tar.xz"
  build_one_meson libXext "$LIBXEXT_VER" \
    "https://www.x.org/releases/individual/lib/libXext-${LIBXEXT_VER}.tar.xz"
  build_one_meson libXrender "$LIBXRENDER_VER" \
    "https://www.x.org/releases/individual/lib/libXrender-${LIBXRENDER_VER}.tar.xz"
  build_one_meson libXfixes "$LIBXFIXES_VER" \
    "https://www.x.org/releases/individual/lib/libXfixes-${LIBXFIXES_VER}.tar.xz"
  build_one_meson libXrandr "$LIBXRANDR_VER" \
    "https://www.x.org/releases/individual/lib/libXrandr-${LIBXRANDR_VER}.tar.xz"
  build_one_meson libXinerama "$LIBXINERAMA_VER" \
    "https://www.x.org/releases/individual/lib/libXinerama-${LIBXINERAMA_VER}.tar.xz"
  build_one_meson libXcursor "$LIBXCURSOR_VER" \
    "https://www.x.org/releases/individual/lib/libXcursor-${LIBXCURSOR_VER}.tar.xz"
  build_one_meson libXi "$LIBXI_VER" \
    "https://www.x.org/releases/individual/lib/libXi-${LIBXI_VER}.tar.xz"
fi

echo ""
echo "Done. Build pipetrace with:"
echo "  export CMAKE_PREFIX_PATH=\"$PREFIX\${CMAKE_PREFIX_PATH:+:\$CMAKE_PREFIX_PATH}\""
echo "  export PKG_CONFIG_PATH=\"$PREFIX/lib/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}\""
echo "  ./build.sh"
echo "Or:"
echo "  cmake -S . -B build -DCMAKE_PREFIX_PATH=$PREFIX -DCMAKE_BUILD_TYPE=Release"
echo "  cmake --build build -j\"\$(nproc)\""
