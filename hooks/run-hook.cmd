: << 'CMDBLOCK'
@echo off
REM DEPRECATED: Claude Code 2.1.x auto-detects .sh files and prepends bash
REM on Windows, making this polyglot wrapper unnecessary. hooks.json now
REM invokes session-start.sh directly. This file is kept for reference only.
REM
REM Original purpose: Polyglot wrapper that runs .sh scripts cross-platform
REM Usage: run-hook.cmd <script-name> [args...]
REM The script should be in the same directory as this wrapper

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)
"C:\Program Files\Git\bin\bash.exe" -l "%~dp0%~1" %2 %3 %4 %5 %6 %7 %8 %9
exit /b
CMDBLOCK

# ABOUTME: Polyglot wrapper that runs .sh scripts cross-platform
# ABOUTME: Works on both Windows (cmd.exe via batch) and Unix (bash)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
