# Offline build commands

Copy-paste on the **remote machine** (no sudo; X11 runtime already works; missing `-dev` packages like `libxrandr-dev`).

Clone via HTTP (as configured on your site):

```bash
git clone http://github.com/dorszman/pipetrace_release.git
cd pipetrace_release
```

Verify downloads (optional):

```bash
sha256sum -c x11-tarballs.sha256
sha256sum -c pipetrace-0.3.4.sha256
```

Extract pipetrace source and enter tree:

```bash
tar -xJf pipetrace-0.3.4.tar.xz
cd pipetrace-0.3.4
```

Bootstrap local X11 dev prefix (fixes RandR / libXrandr header errors):

```bash
../scripts/bootstrap_x11_prefix.sh --tarball-dir ../x11-tarballs
```

Build everything (viewer + tools):

```bash
./build.sh
```

Binaries are under `build/`:

```bash
ls -1 build/pipetrace-*
```

Example run (after you have an **analyzed** store with embedded config):

```bash
./build/pipetrace-view PATH.db
```

Analyzed stores carry `app_config_json` in meta, so a sidecar config file is not required. For developer builds, CMake may still copy `config/pipetrace.linx.json` → `pipetrace.app.json` next to `pipetrace-view` (useful for older DBs without an embed). Resolution order: store embed, then `--config`, then `PIPETRACE_CONFIG`, then exe-adjacent `pipetrace.app.json`. Positional store paths: `pipetrace-view [a.db] [b.db]`.

### Windows notes

The Windows ZIP ships **`pipetrace-view.exe` + `LICENSE` only** — no `pipetrace.app.json`. Open an analyzed `.db` (embed supplies config). Use repo-root `tiny_analyzed.db` for a smoke open:

```text
pipetrace-view.exe tiny_analyzed.db
```

(or drag-and-drop / Open with).

---

## If GUI still fails (OpenGL dev headers missing)

Build CLI tools only:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DPIPetrace_BUILD_GUI=OFF
cmake --build build -j"$(nproc)"
```

---

## Prerequisites on remote (must exist; not in this bundle)

- `g++` (build-essential)
- `cmake` 3.20+
- X11 **runtime** libs (you said X11 works — good)
- OpenGL dev headers for viewer (`libgl-dev` or equivalent) — ask admin if GUI build fails

---

## One-liner sequence (after clone)

```bash
cd pipetrace_release && \
sha256sum -c x11-tarballs.sha256 && \
tar -xJf pipetrace-0.3.4.tar.xz && \
cd pipetrace-0.3.4 && \
../scripts/bootstrap_x11_prefix.sh --tarball-dir ../x11-tarballs && \
./build.sh
```
