@echo off
rem Bella Napolia: prepares a Windows 7 computer to run the till in Chrome.
rem Run once, with a right click > "Run as administrator".
setlocal EnableExtensions
title Bella Napolia - Installation de la caisse
set "URL=https://yassir1778.github.io/napolia/caisse/"

net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Clic droit sur ce fichier, puis "Executer en tant qu'administrateur".
  echo.
  pause
  exit /b 1
)

echo.
echo  ===== Bella Napolia : preparation de la caisse =====
echo.

rem --- 1. Chrome (109 is the last version for Windows 7)
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if not defined CHROME call :installchrome
if not defined CHROME (
  echo  [!] Chrome n'a pas pu etre installe. Verifiez internet et relancez ce fichier.
  echo.
  pause
  exit /b 1
)
echo  [1/6] Chrome trouve : %CHROME%

rem --- 2. Chrome rules for the till (policies)
set "POL=HKLM\SOFTWARE\Policies\Google\Chrome"
rem No developer tools: nobody can change the till from inside the browser.
reg add "%POL%" /v DeveloperToolsAvailability /t REG_DWORD /d 2 /f >nul
rem No "translate this page", no password prompts, no "Windows 7 not supported" bar.
reg add "%POL%" /v TranslateEnabled /t REG_DWORD /d 0 /f >nul
reg add "%POL%" /v PasswordManagerEnabled /t REG_DWORD /d 0 /f >nul
reg add "%POL%" /v SuppressUnsupportedOSWarning /t REG_DWORD /d 1 /f >nul
rem Chrome does not stay running in the background after the till is closed.
reg add "%POL%" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul
rem Tickets go to Windows' default printer (the receipt printer).
reg add "%POL%" /v PrintPreviewUseSystemDefaultPrinter /t REG_DWORD /d 1 /f >nul
echo  [2/6] Regles de Chrome appliquees

rem --- 3. The till's shortcut: full screen, silent printing, no zoom by pinching
set "ARGS=--kiosk --kiosk-printing --no-first-run --disable-pinch --overscroll-history-navigation=0 %URL%"
set "VBS=%TEMP%\bella_shortcut.vbs"
> "%VBS%" echo Set sh = CreateObject("WScript.Shell")
>> "%VBS%" echo For Each p In Array(WScript.Arguments(0), WScript.Arguments(1))
>> "%VBS%" echo   Set l = sh.CreateShortcut(p ^& "\Bella Napolia Caisse.lnk")
>> "%VBS%" echo   l.TargetPath = WScript.Arguments(2)
>> "%VBS%" echo   l.Arguments = WScript.Arguments(3)
>> "%VBS%" echo   l.IconLocation = WScript.Arguments(2) ^& ",0"
>> "%VBS%" echo   l.Save
>> "%VBS%" echo Next
cscript //nologo "%VBS%" "%PUBLIC%\Desktop" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\StartUp" "%CHROME%" "%ARGS%"
del "%VBS%" >nul 2>&1
echo  [3/6] Raccourci "Bella Napolia Caisse" sur le bureau, et ouverture au demarrage

rem --- 4. Never sleep, never turn the screen off while plugged in
powercfg -change -standby-timeout-ac 0 >nul
powercfg -change -monitor-timeout-ac 0 >nul
powercfg -change -hibernate-timeout-ac 0 >nul
echo  [4/6] Mise en veille desactivee

rem --- 5. Moroccan time (UTC+1), set from the internet
rem Windows' Casablanca zone is right only when its rules reach this year (the
rem Ramadan hour included); an older Windows 7 gets West Central Africa (UTC+1).
set "ZONE=W. Central Africa Standard Time"
for /f "tokens=3" %%Y in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Morocco Standard Time\Dynamic DST" /v LastEntry 2^>nul ^| find "LastEntry"') do if %%Y GEQ 2026 set "ZONE=Morocco Standard Time"
tzutil /s "%ZONE%"
sc config w32time start= auto >nul
net start w32time >nul 2>&1
w32tm /config /manualpeerlist:"time.windows.com,0x9 pool.ntp.org,0x9" /syncfromflags:manual /update >nul
w32tm /resync /rediscover >nul 2>&1
echo  [5/6] Fuseau horaire : %ZONE% ; heure reglee par internet
echo        Heure de l'ordinateur maintenant : %TIME:~0,5%  (comparez avec votre telephone)

rem --- 6. Printers: the receipt printer must be the default one
echo  [6/6] Imprimantes installees (Default=TRUE : imprimante par defaut) :
wmic printer get Name,Default 2>nul
echo.
echo  ===== Termine =====
echo  - Si l'imprimante de tickets n'est pas "TRUE" ci-dessus : Demarrer ^> Peripheriques
echo    et imprimantes ^> clic droit sur elle ^> "Definir comme imprimante par defaut".
echo  - Fermez Chrome, puis ouvrez "Bella Napolia Caisse" sur le bureau.
echo  - Pour quitter la caisse en plein ecran : Alt + F4.
echo.
pause
exit /b 0

rem Today's Chrome needs Windows 10: Windows 7 takes Chrome 109, its last
rem version, from Google's own server; installed only if Google signed it.
:installchrome
set "CH_URL=https://dl.google.com/release2/chrome/czao2hrvpk5wgqrkz4kks5r734_109.0.5414.120/109.0.5414.120_chrome_installer.exe"
if /i not "%PROCESSOR_ARCHITECTURE%"=="AMD64" if not defined PROCESSOR_ARCHITEW6432 set "CH_URL=https://dl.google.com/release2/chrome/acihtkcueyye3ymoj2afvv7ulzxa_109.0.5414.120/109.0.5414.120_chrome_installer.exe"
set "CH_EXE=%TEMP%\chrome109_installer.exe"
rem Brought on a USB stick next to this file: no download needed.
if exist "%~dp0109.0.5414.120_chrome_installer.exe" (
  echo  [1/6] Chrome n'est pas installe : installateur trouve a cote de ce fichier.
  copy /y "%~dp0109.0.5414.120_chrome_installer.exe" "%CH_EXE%" >nul
) else (
  echo  [1/6] Chrome n'est pas installe : telechargement de Chrome 109 - environ 90 Mo...
  bitsadmin /transfer BellaChrome /priority foreground "%CH_URL%" "%CH_EXE%" >nul
)
if not exist "%CH_EXE%" exit /b 0
powershell -NoProfile -Command "$s = Get-AuthenticodeSignature '%CH_EXE%'; if ($s.Status -eq 'Valid' -and $s.SignerCertificate.Subject -like '*Google*') { exit 0 } else { exit 1 }"
if errorlevel 1 (
  echo  [!] Le fichier telecharge n'est pas signe par Google : il n'est pas installe.
  del "%CH_EXE%" >nul 2>&1
  exit /b 0
)
echo        Installation de Chrome 109...
"%CH_EXE%" --system-level --do-not-launch-chrome
del "%CH_EXE%" >nul 2>&1
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
exit /b 0
