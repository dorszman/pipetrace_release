# TEMPORARY — Windows silent-exit handoff (delete after fix)

> **Status:** TEMPORARY debugging handoff for Cursor on the user's home Windows machine.  
> **Delete this file** (and remove the README pointer) once the silent-exit bug is fixed and verified.

## Goal

Diagnose why **pipetrace-view v0.3.4** (and later 0.3.x) **silent-exits on Windows** when opening `tiny_analyzed.db`, while **v0.2.0 works on the same machine with the same DB**.

Symptoms of the broken builds:

- Process exits immediately
- **No** error MessageBox / dialog
- **No** `pipetrace-view.log` found (or none that the user noticed)

## What this public repo is

Repo: [dorszman/pipetrace_release](https://github.com/dorszman/pipetrace_release)  
**Release-only** (binaries, offline source tarballs, fixture DB). Not the full private development tree.

Private source (rebuild / fix code): **dorszman/pipetrace**  
Public release: **dorszman/pipetrace_release** (this folder)

## Artifacts to use (already in this repo)

| Artifact | Role |
|----------|------|
| `pipetrace-v0.2.0-windows.zip` | **WORKING** baseline on this machine |
| `pipetrace-v0.3.4-windows.zip` | **BROKEN** — contains `pipetrace-view.exe` + `LICENSE` only (**no** `pipetrace.app.json`) |
| `pipetrace-v0.3.6-windows.zip` | **Preferred debug kit** if present — exe + `tiny_analyzed.db` + `run_debug.bat` + `README_WINDOWS_DEBUG.txt` (multi-path logs) |
| `tiny_analyzed.db` | Analyzed fixture with embedded `app_config_json` in SQLite `meta` (also inside the 0.3.6 zip) |

Raw / blob URLs (if clone is awkward):

- Repo: https://github.com/dorszman/pipetrace_release
- Working zip: https://github.com/dorszman/pipetrace_release/raw/main/pipetrace-v0.2.0-windows.zip
- Broken zip: https://github.com/dorszman/pipetrace_release/raw/main/pipetrace-v0.3.4-windows.zip
- Debug kit zip: https://github.com/dorszman/pipetrace_release/raw/main/pipetrace-v0.3.6-windows.zip
- Fixture DB: https://github.com/dorszman/pipetrace_release/raw/main/tiny_analyzed.db
- This handoff: https://github.com/dorszman/pipetrace_release/blob/main/WINDOWS_DEBUG_HANDOFF.md

Zip contents (for orientation):

- **v0.2.0:** `pipetrace-view.exe`, `LICENSE`, `pipetrace.app.json`
- **v0.3.4:** `pipetrace-view.exe`, `LICENSE` only (config sidecar intentionally removed)

## Critical context (do not mis-diagnose)

1. **Not drivers / not OpenGL install.** v0.2.0 opens the same DB on this same PC → GPU/OpenGL stack works.
2. **Missing `pipetrace.app.json` is intentional** for 0.3.4+ Windows ZIPs. The viewer must load config from the DB embed (`meta.app_config_json`). `tiny_analyzed.db` **has** that embed — do **not** “fix” by requiring a sidecar JSON for this fixture.
3. Silent exit with **no log** is the bug to chase (early abort, wrong log path, or crash before logging).

## Exact repro steps (Windows)

Work in a **writable** folder (e.g. Desktop). Do **not** run from a read-only zip preview or locked network share.

### A) Prepare folders

```bat
mkdir %USERPROFILE%\Desktop\pt-020
mkdir %USERPROFILE%\Desktop\pt-034
```

Extract:

- `pipetrace-v0.2.0-windows.zip` → `pt-020\`
- `pipetrace-v0.3.4-windows.zip` → `pt-034\`

Copy the fixture next to each exe:

```bat
copy tiny_analyzed.db %USERPROFILE%\Desktop\pt-020\
copy tiny_analyzed.db %USERPROFILE%\Desktop\pt-034\
```

### B) Run WORKING baseline (v0.2.0)

```bat
cd /d %USERPROFILE%\Desktop\pt-020
pipetrace-view.exe tiny_analyzed.db
echo EXITCODE=%ERRORLEVEL%
```

Or drag-and-drop `tiny_analyzed.db` onto `pipetrace-view.exe`.  
**Expect:** window opens. Note exit code after closing.

### C) Run BROKEN candidate (v0.3.4)

```bat
cd /d %USERPROFILE%\Desktop\pt-034
pipetrace-view.exe tiny_analyzed.db
echo EXITCODE=%ERRORLEVEL%
```

Or drag-and-drop the same `tiny_analyzed.db` onto the 0.3.4 exe.  
**Observe:** likely immediate exit; capture `%ERRORLEVEL%`.

Also try with an explicit title (harmless; helps identify the window if it ever appears):

```bat
pipetrace-view.exe --title win-debug tiny_analyzed.db
echo EXITCODE=%ERRORLEVEL%
```

### D) Hunt for logs (all three places)

After each run, check:

1. Beside the exe: `pt-034\pipetrace-view.log`
2. Current working directory (if different from exe dir)
3. `%TEMP%\pipetrace-view.log`

```bat
dir %USERPROFILE%\Desktop\pt-034\pipetrace-view.log
dir pipetrace-view.log
dir %TEMP%\pipetrace-view.log
```

If a log exists, copy it to Desktop and keep the full text. If **none** exist, say so explicitly — that is important evidence.

### E) Optional A/B notes

- Confirm 0.2.0 folder still has `pipetrace.app.json`; 0.3.4 does not.
- Do **not** copy `pipetrace.app.json` from 0.2.0 into 0.3.4 as the “fix” unless you are testing a hypothesis — the product requirement is DB-embed config for analyzed stores.

## Preferred capture path (if `pipetrace-v0.3.6-windows.zip` is present)

1. Unzip `pipetrace-v0.3.6-windows.zip` to a writable folder (e.g. Desktop\pipetrace-debug).
2. Double-click `run_debug.bat` (keeps console open; prints exit code; copies logs to Desktop).
3. Still A/B with extracted `pipetrace-v0.2.0-windows.zip` + same `tiny_analyzed.db` to prove the machine/OpenGL baseline.
4. If 0.3.6 still silent-exits, you already have the always-on / multi-path log attempt — report exit code + whether Desktop `pipetrace-view*.log` copies exist.

## What the Windows agent should do

1. **Reproduce** with the steps above; record exit codes for 0.2.0 vs 0.3.4.
2. **Compare** behavior and any logs / missing logs.
3. **If private source is available** (`dorszman/pipetrace` clone / Cursor workspace with sources): find the early-exit path, fix it, and prefer **always-on startup logging** (exe dir + `%TEMP%` + cwd) and/or ship `run_debug.bat` so silent exits cannot vanish.
4. **If only this public release folder is available:** do not invent a fake fix; report concrete evidence (exit codes, log presence/absence, paths tried, whether MessageBox appeared). Suggest next release should include always-on logs / `run_debug.bat` if still silent.
5. Mark progress in chat; when fixed and verified on this machine, **delete** `WINDOWS_DEBUG_HANDOFF.md` and the README one-liner pointing to it.

## Out of scope

- Reinstalling GPU drivers
- Requiring `pipetrace.app.json` next to the 0.3.4 exe for `tiny_analyzed.db`
- Treating this public repo as the place to land large private source trees (push fixes via private `pipetrace` → new tagged Windows ZIP here)

## Success criteria

- Root cause identified with exit-code / log evidence, **or**
- Fixed viewer opens `tiny_analyzed.db` on this Windows machine without a config sidecar, and leaves a usable log on failure
