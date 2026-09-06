@echo off
setlocal EnableExtensions
REM Real-Windows debug launcher for pipetrace-view.
REM Double-click this file (or run from cmd). It will NOT exit silently.

cd /d "%~dp0"
set "PIPETRACE_DEBUG_CONSOLE=1"
set "PIPETRACE_NO_MESSAGEBOX="
set "CI="
set "GITHUB_ACTIONS="

echo ========================================
echo pipetrace Windows debug runner
echo Folder: %CD%
echo Time:   %DATE% %TIME%
echo ========================================
echo.

if not exist "pipetrace-view.exe" (
  echo ERROR: pipetrace-view.exe not found next to this script.
  echo Put run_debug.bat in the same folder as the exe.
  goto :pause_fail
)

if exist "tiny_analyzed.db" (
  set "DB=%CD%\tiny_analyzed.db"
) else if exist "%~1" (
  set "DB=%~1"
) else (
  echo No tiny_analyzed.db next to this script.
  echo Drag a .db onto this .bat, or pass a path:
  echo   run_debug.bat C:\path\to\trace.db
  if "%~1"=="" goto :pause_fail
)

echo Using DB: %DB%
echo.
echo Clearing old logs...
del /q "%CD%\pipetrace-view.log" 2>nul
del /q "%TEMP%\pipetrace-view.log" 2>nul
del /q "%USERPROFILE%\Desktop\pipetrace-view*.log" 2>nul

echo.
echo Launching: pipetrace-view.exe --title win-debug "%DB%"
echo ----------------------------------------
pipetrace-view.exe --title win-debug "%DB%"
set "ERR=%ERRORLEVEL%"
echo ----------------------------------------
echo Exit code: %ERR%
echo.

echo ---- %CD%\pipetrace-view.log ----
if exist "%CD%\pipetrace-view.log" (
  type "%CD%\pipetrace-view.log"
) else (
  echo (missing)
)
echo.
echo ---- %TEMP%\pipetrace-view.log ----
if exist "%TEMP%\pipetrace-view.log" (
  type "%TEMP%\pipetrace-view.log"
) else (
  echo (missing)
)
echo.

REM Copy evidence to Desktop for easy paste-back
if exist "%CD%\pipetrace-view.log" copy /y "%CD%\pipetrace-view.log" "%USERPROFILE%\Desktop\pipetrace-view.exe-dir.log" >nul
if exist "%TEMP%\pipetrace-view.log" copy /y "%TEMP%\pipetrace-view.log" "%USERPROFILE%\Desktop\pipetrace-view.temp.log" >nul
echo Copied available logs to Desktop as:
echo   pipetrace-view.exe-dir.log
echo   pipetrace-view.temp.log
echo.

if not "%ERR%"=="0" (
  echo FAILED with exit code %ERR%.
  echo Please send Desktop log copies + this exit code back.
  goto :pause_fail
)

echo OK ^(exit 0^). If the window flashed and closed, still send the Desktop logs.
goto :pause_ok

:pause_fail
echo.
pause
exit /b 1

:pause_ok
echo.
pause
exit /b 0
