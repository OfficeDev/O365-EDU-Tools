@echo off
setlocal
REM Titlebar only. It prints nothing, so nothing that reads this launcher's output sees a difference,
REM and it is the same wording the .ps1 puts in its own banner and titlebar. In the elevated shape
REM there are two windows on the taskbar and neither used to say which run it belonged to.
title Service Usage Assessment
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%Assessment Script.ps1"

REM Which of the two launch shapes is this? The script self-elevates only when it is NOT already
REM administrator, and that single fact decides everything the banner below promises: whether a UAC
REM prompt appears, whether a second window opens, and which window the run actually happens in.
REM The banner used to state the standard-user path unconditionally, so for anyone already elevated
REM all three numbered promises were false: no prompt, no new window, and the run happening right
REM here rather than somewhere else.
REM No attempt is made to detect elevation here. The wording below is instead true of BOTH cases,
REM which is all DEV-006 actually asked for. Detecting it was tried and abandoned: "fltmc" is blocked
REM by Application Control policy on this estate, and its failure is indistinguishable from "not
REM admin", so every elevated run would have been misreported; asking PowerShell instead works but
REM adds a process start and a new way for the launcher itself to be wrong, to buy nothing the test
REM plan asked for.
REM Nineteen spaces on the title line, not eighteen: cmd eats exactly one of them as the separator
REM between ECHO and its message, so the first never prints. The remaining eighteen centre the
REM 24-character title in the 60-character rule, which is the same banner the .ps1 prints. ASCII
REM only, because box-drawing characters would be mangled by whatever codepage the console happens
REM to be in, which is also why the rules are '='.
REM Every line of body text is wrapped by hand to stay inside those same 60 columns, and each step is
REM separated by a blank line. Both are deliberate. Left to the console to wrap, the continuation of
REM a numbered step began hard against the left margin at whatever width the window happened to be,
REM so the three steps ran together into a paragraph and the numbers stopped reading as a list. The
REM indent is what makes a continuation line obviously part of the step above it, and that only holds
REM if the wrap point is fixed here rather than decided by the window.
echo ============================================================
echo                   Service Usage Assessment
echo ============================================================
echo.
echo This will:
echo.
echo    1. Ask Windows for administrator approval ^(a UAC prompt^).
echo       If this window is already running as administrator,
echo       there is no prompt.
echo.
echo    2. Run the assessment: in a NEW PowerShell window if
echo       approval had to be asked for, otherwise right here in
echo       this window.
echo.
echo    3. Open a browser sign-in window. Sign in with your admin
echo       account.
echo.
echo ============================================================
echo.
echo  If a NEW window opens, watch that one. THIS window then
echo  closes by itself, which is expected.
echo.
pause

REM Checked before launching so a missing or renamed .ps1 produces a sentence a non-technical user
REM can act on, rather than PowerShell's own "The argument ... does not exist" wording.
REM The path is given its own indented line rather than being run into the sentence: it is long, it is
REM the one part the reader has to compare against what is on disk, and wrapped mid-path it is
REM unreadable.
if not exist "%PS1%" (
    echo.
    echo ============================================================
    echo  [ERROR] The assessment script was not found
    echo ============================================================
    echo.
    echo Expected it next to this launcher, at:
    echo.
    echo    %PS1%
    echo.
    echo Keep this .bat and the .ps1 together in the same folder,
    echo with their original file names, then run this launcher
    echo again.
    echo.
    pause
    endlocal
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

REM Captured on its own line on purpose. Inside an if-block, %ERRORLEVEL% would be substituted when
REM cmd parses the whole block, that is, before powershell.exe has run, so it would report a stale
REM value. A separate SET runs after powershell returns and freezes the real code.
set "RC=%ERRORLEVEL%"

REM Compared as a string rather than with "if errorlevel 1", which means "1 or greater" and so misses
REM the negative codes a crashed or blocked host returns (-1, -196608, 0xC000...).
if not "%RC%"=="0" goto :failed
goto :done

:failed
REM Exit code on its own line, aligned under the message rather than trailing it. It is the one thing
REM worth quoting when reporting the failure, and at the end of a sentence it was routinely missed.
echo.
echo ============================================================
echo  [ERROR] The assessment did not start, or it ended
echo          with an error.
echo.
echo          Exit code: %RC%
echo ============================================================
echo.
echo Read the message above this line first.
echo.
echo If the run got far enough to create a log, there will be
echo more detail in:
echo.
echo    %SCRIPT_DIR%Resources\Logs.log
echo.
pause
goto :done

REM Deliberately no pause on success. The .ps1 now ends with its own "Press any key to continue"
REM (Wait-ForOperator, called from its outer finally), so whichever window the run happened in stays
REM open until the operator has read the closing summary. Pausing again here would ask the same
REM question twice in the already-elevated shape.
REM The former KNOWN LIMITATION is closed by that same pause: when the launcher is started from an
REM ALREADY elevated console the script does not relaunch, so the run happens in THIS window, and the
REM script's own keypress is what now stops the summary scrolling away as it closes. Region 0 no
REM longer passes -NoExit for the same reason; a keypress that ends the window replaced a prompt that
REM nothing ever closed.

:done
REM Both on ONE line on purpose. ENDLOCAL discards every variable set since SETLOCAL, RC included, so
REM a separate "exit /b %RC%" on the next line would find RC already gone and silently return the
REM errorlevel of the last thing that ran (PAUSE, which always succeeds), turning every failure into
REM exit code 0. Joined with &, cmd substitutes RC's value while it still exists, then runs ENDLOCAL,
REM then exits with the literal number.
endlocal & exit /b %RC%
