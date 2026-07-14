@echo off
setlocal
set "SRC=%~dp0.."
if exist "%~dp0..\skills\multi-agent-system" set "SRC=%~dp0.."
if exist "%~dp0skills\multi-agent-system" set "SRC=%~dp0"

set "DEST=%USERPROFILE%\.cursor"
echo Installing MAS to %DEST%
echo From %SRC%
echo.

if not exist "%DEST%" mkdir "%DEST%"

for %%D in (skills commands rules hooks) do (
  if exist "%SRC%\%%D" (
    echo Copying %%D ...
    xcopy "%SRC%\%%D" "%DEST%\%%D\" /E /I /Y >nul
  )
)

if exist "%SRC%\USER-RULE-MAS.md" copy /Y "%SRC%\USER-RULE-MAS.md" "%DEST%\" >nul

echo.
echo Done. Reload Cursor, then type /mas in chat.
pause
