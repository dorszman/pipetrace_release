pipetrace — Windows real-machine debug kit
==========================================

Why this exists
---------------
On the remote Windows host, v0.2.0 opens tiny_analyzed.db successfully, but
v0.3.4 exits immediately with no MessageBox and no pipetrace-view.log found.
That usually means either:
  (1) the log was written somewhere unexpected (exe dir vs cwd vs %TEMP%), or
  (2) the process died before / without a visible UI, or
  (3) write permission next to the exe failed silently.

This kit makes silent exits impossible to miss.

What to download
----------------
From https://github.com/dorszman/pipetrace_release :
  - pipetrace-v0.3.6-windows.zip  (or newer)  ← this kit
  - Keep pipetrace-v0.2.0-windows.zip nearby for A/B

Steps on the remote Windows machine
-----------------------------------
1. Unzip pipetrace-v0.3.6-windows.zip to a WRITABLE folder, e.g.
     C:\Users\<you>\Desktop\pipetrace-debug\
   Do NOT run from a network share / read-only zip preview.

2. Confirm the folder contains at least:
     pipetrace-view.exe
     LICENSE
     tiny_analyzed.db
     run_debug.bat
     README_WINDOWS_DEBUG.txt

3. Double-click run_debug.bat
   - A console window stays open
   - It launches: pipetrace-view.exe --title win-debug tiny_analyzed.db
   - It prints the exit code
   - It types any logs it finds
   - It copies logs to your Desktop:
       pipetrace-view.exe-dir.log
       pipetrace-view.temp.log
   - It pauses (Press any key...) so the window cannot vanish

4. A/B with v0.2.0 (optional but helpful):
   - Unzip v0.2.0 to a SECOND folder
   - Copy tiny_analyzed.db into that folder
   - Run: pipetrace-view.exe tiny_analyzed.db
   - Confirm it still works

What to send back
-----------------
1. Exit code printed by run_debug.bat
2. Desktop files:
     pipetrace-view.exe-dir.log
     pipetrace-view.temp.log
   (if a file is missing, say so)
3. Screenshot of the console window and any MessageBox
4. Exact folder path where you unzipped (e.g. Desktop\pipetrace-debug)

Env vars used by the debug runner
---------------------------------
  PIPETRACE_DEBUG_CONSOLE=1   allocate a console and mirror logs to it
  CI / GITHUB_ACTIONS / PIPETRACE_NO_MESSAGEBOX are cleared by the .bat
    so MessageBox fatals are not suppressed

Normal (non-debug) use
----------------------
  pipetrace-view.exe path\to\analyzed.db
Logs are written to:
  - next to pipetrace-view.exe
  - %TEMP%\pipetrace-view.log
  - current working directory\pipetrace-view.log
