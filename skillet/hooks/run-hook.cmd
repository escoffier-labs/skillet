: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for hook scripts.
REM On Windows: cmd.exe runs the batch portion, which finds and calls bash.
REM On Unix: the shell interprets this as a script (: is a no-op in bash).
REM
REM Hook scripts use extensionless filenames (e.g. "session-start" not
REM "session-start.sh") so Claude Code's Windows auto-detection -- which
REM prepends "bash" to any command containing .sh -- doesn't interfere.
REM
REM Usage: run-hook.cmd <script-name> [args...]

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)

setlocal
set "HOOK_DIR=%~dp0"
set "BASH_EXE="

REM 1. Git for Windows in its system-wide locations.
if exist "C:\Program Files\Git\bin\bash.exe" set "BASH_EXE=C:\Program Files\Git\bin\bash.exe"
if not defined BASH_EXE if exist "C:\Program Files (x86)\Git\bin\bash.exe" set "BASH_EXE=C:\Program Files (x86)\Git\bin\bash.exe"

REM 2. Per-user Git for Windows install (no admin rights needed). Guard on
REM LOCALAPPDATA being defined: unset, the path would collapse to
REM \Programs\Git\... on the current drive, which any user can create.
if not defined BASH_EXE if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"

REM 3. bash from PATH (MSYS2, Cygwin, a non-default Git install). Call where.exe
REM by absolute path and search PATH only ($PATH:), so neither where nor bash
REM can be resolved from the current directory. Skip hits with no extension and
REM the WSL launchers (System32, Sysnative, the Store alias), which fail when
REM no Linux distribution is installed.
if not defined BASH_EXE if defined SystemRoot for /f "delims=" %%B in ('"%SystemRoot%\System32\where.exe" $PATH:bash 2^>nul') do if not defined BASH_EXE if not "%%~xB"=="" if /i not "%%~dpB"=="%SystemRoot%\System32\" if /i not "%%~dpB"=="%SystemRoot%\Sysnative\" if /i not "%%~dpB"=="%LOCALAPPDATA%\Microsoft\WindowsApps\" set "BASH_EXE=%%B"

REM No bash found - exit silently rather than error
REM (plugin still works, just without SessionStart context injection).
if not defined BASH_EXE exit /b 0

REM Run bash outside any parenthesized block. cmd expands %ERRORLEVEL% when it
REM parses a block, which would lose the hook's real exit code.
"%BASH_EXE%" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%
CMDBLOCK

# Unix: run the named script directly.
# Split $0 on its last / or \ instead of calling dirname, and start the script
# with $BASH (bash's own absolute path) instead of a PATH lookup, so this keeps
# working when the harness spawns the hook with an empty or broken PATH.
case "$0" in
  */*|*\\*) SCRIPT_DIR="$(cd "${0%[/\\]*}" && pwd)" ;;
  *) SCRIPT_DIR="$(pwd)" ;;
esac
SCRIPT_NAME="$1"
shift
exec "${BASH:-bash}" "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
