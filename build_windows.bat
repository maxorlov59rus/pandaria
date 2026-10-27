@echo off
rem ============================================================
rem  Pandaria 5.4.8 (Legends of Azeroth) - Windows build script
rem  Requires: Visual Studio 2022 (MSVC v143), CMake >= 3.16,
rem            Boost 1.87.0, OpenSSL 3.x x64, MySQL/MariaDB SDK
rem  Usage:    build_windows.bat [Debug|Release|RelWithDebInfo]
rem            (default: RelWithDebInfo, same as CI workflow)
rem ============================================================
setlocal

set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=RelWithDebInfo"

rem ---- Dependency locations (override via environment before run) ----
if "%BOOST_ROOT%"==""        set "BOOST_ROOT=C:\Libraries\boost_1_87_0"
if "%OPENSSL_ROOT_DIR%"==""  set "OPENSSL_ROOT_DIR=C:\Program Files\OpenSSL-Win64"
if "%MYSQL_INCLUDE_DIR%"=="" set "MYSQL_INCLUDE_DIR=C:\Program Files\MySQL\MySQL Server 8.0\include"
if "%MYSQL_LIBRARY%"==""     set "MYSQL_LIBRARY=C:\Program Files\MySQL\MySQL Server 8.0\lib\libmysql.lib"

rem Repo root (structure moved to repo root: CMakeLists.txt, server/, contrib/ live here)
set "SRC_DIR=%~dp0"
set "BUILD_DIR=%SRC_DIR%build-win"
set "DEPLOY_BIN=%SRC_DIR%server\bin\windows"

echo [i] Checking tools...
cmake --version >nul 2>&1 || (echo [!] CMake not found in PATH. Install: winget install Kitware.CMake & exit /b 1)
where git >nul 2>&1 || echo [w] git not found - revision will be 'no-commit-hash-Available'

rem ---- MSVC compiler check (project requires C++20 -> VS 2022 v143 only) ----
set "VSOK="
for %%Y in (2022) do (
  for %%E in (Enterprise Professional Community BuildTools) do (
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\%%Y\%%E\VC\Tools\MSVC" set "VSOK=1"
    if exist "%ProgramFiles%\Microsoft Visual Studio\%%Y\%%E\VC\Tools\MSVC" set "VSOK=1"
  )
)
if not defined VSOK (
  where cl >nul 2>&1 || (echo [!] MSVC compiler not found. Install Visual Studio 2022 with the "Desktop development with C++" workload ^(winget install Microsoft.VisualStudio.2022.Community --override "--add Microsoft.VisualStudio.Workload.NativeDesktop"^). & exit /b 1)
)

if not exist "%BOOST_ROOT%"       (echo [!] BOOST_ROOT not found: %BOOST_ROOT% & exit /b 1)
if not exist "%OPENSSL_ROOT_DIR%" (echo [!] OPENSSL_ROOT_DIR not found: %OPENSSL_ROOT_DIR% & exit /b 1)
if not exist "%MYSQL_LIBRARY%"    (echo [!] MYSQL_LIBRARY not found: %MYSQL_LIBRARY% & exit /b 1)
rem ---- WIN64 dependency guards: OpenSSL and MySQL client must be 64-bit ^(x64^) builds ----
if not exist "%OPENSSL_ROOT_DIR%\bin\libcrypto-3-x64.dll" if not exist "%OPENSSL_ROOT_DIR%\lib\libcrypto.lib" (
  echo [!] OpenSSL 64-bit files not found in "%OPENSSL_ROOT_DIR%" - install the x64 OpenSSL 3.x build ^(e.g. via winget Slshsvaer.OpenSSL or FireDaemon distribution^)
  exit /b 1
)
if not exist "%MYSQL_INCLUDE_DIR%" (
  echo [!] MYSQL_INCLUDE_DIR not found: "%MYSQL_INCLUDE_DIR%" - install the MySQL/MariaDB 64-bit development headers
  exit /b 1
)

rem ---- Boost version check (Windows build requires >= 1.78, project pins 1.87.0) ----
rem boost/version.hpp defines e.g.:  #define BOOST_VERSION 108700  (= 1.87.00)
set "BOOST_NUM="
for /f "usebackq tokens=3" %%V in (`findstr /r /c:"^[ ]*#[ ]*define[ ]*BOOST_VERSION " "%BOOST_ROOT%\boost\version.hpp" 2^>nul`) do set "BOOST_NUM=%%V"
if not defined BOOST_NUM (
  echo [!] Could not read/parse BOOST_VERSION from "%BOOST_ROOT%\boost\version.hpp" - does BOOST_ROOT point to a real Boost installation?
  exit /b 1
)
rem BOOST_VERSION = MAJOR*100000 + MINOR*100 + PATCH (e.g. 108700 -> 1.87)
set /a "BOOST_TOTAL=%BOOST_NUM%"
set /a "BOOST_MIN=BOOST_TOTAL%%10000/100"
set /a "BOOST_REQ=107800"
if %BOOST_TOTAL% LSS %BOOST_REQ% (
  echo [!] Boost too old: found 1.%BOOST_MIN% ^(%BOOST_NUM%^) - Windows builds require 1.78+, recommended 1.87.0
  exit /b 1
)
echo [i] Boost version OK: 1.%BOOST_MIN% ^(%BOOST_NUM%^)

echo [i] Configuring (generator: Visual Studio 17 2022, arch: x64)...
rem ---- WIN64 guard: clean re-config if the build dir was created for Win32 ----
if exist "%BUILD_DIR%\CMakeCache.txt" findstr /c:"CMAKE_GENERATOR_PLATFORM:INTERNAL=Win32" "%BUILD_DIR%\CMakeCache.txt" >nul 2>&1 && (
  echo [!] Existing build directory is configured for Win32 - deleting it to re-configure as x64 ^(WIN64^)
  rmdir /s /q "%BUILD_DIR%"
)
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

cmake -S "%SRC_DIR%." -B "%BUILD_DIR%" ^
  -G "Visual Studio 17 2022" -A x64 ^
  -DTOOLS=ON -DELUNA=1 ^
  -DBOOST_ROOT="%BOOST_ROOT%" ^
  -DOPENSSL_ROOT_DIR="%OPENSSL_ROOT_DIR%" ^
  -DMYSQL_INCLUDE_DIR="%MYSQL_INCLUDE_DIR%" ^
  -DMYSQL_LIBRARY="%MYSQL_LIBRARY%"
if errorlevel 1 (echo [!] Configure failed & exit /b 1)

echo [i] Building %CONFIG% ...
cmake --build "%BUILD_DIR%" --config %CONFIG% --parallel
if errorlevel 1 (echo [!] Build failed & exit /b 1)

set "OUT_DIR=%BUILD_DIR%\bin\%CONFIG%"
if not exist "%OUT_DIR%" set "OUT_DIR=%BUILD_DIR%\bin\Release"

echo [i] Deploying binaries to %DEPLOY_BIN% ...
if not exist "%DEPLOY_BIN%" mkdir "%DEPLOY_BIN%"
copy /Y "%OUT_DIR%\*.exe" "%DEPLOY_BIN%\" >nul

rem ---- Runtime DLLs next to executables (mirrors CI workflow) ----
if exist "C:\Program Files\MySQL\MySQL Server 8.0\lib\libmysql.dll" ^
  copy /Y "C:\Program Files\MySQL\MySQL Server 8.0\lib\libmysql.dll" "%DEPLOY_BIN%\" >nul
if exist "%OPENSSL_ROOT_DIR%\bin\libcrypto-3-x64.dll" ^
  copy /Y "%OPENSSL_ROOT_DIR%\bin\libcrypto-3-x64.dll" "%DEPLOY_BIN%\" >nul
if exist "%OPENSSL_ROOT_DIR%\bin\libssl-3-x64.dll" ^
  copy /Y "%OPENSSL_ROOT_DIR%\bin\libssl-3-x64.dll" "%DEPLOY_BIN%\" >nul
if exist "%BOOST_ROOT%\lib" for %%f in (boost_*.dll) do ^
  if exist "%BOOST_ROOT%\lib\%%f" copy /Y "%BOOST_ROOT%\lib\%%f" "%DEPLOY_BIN%\" >nul

rem ---- Lua scripts for Eluna ----
if exist "%SRC_DIR%contrib\lua_scripts" (
  if not exist "%DEPLOY_BIN%\lua_scripts" mkdir "%DEPLOY_BIN%\lua_scripts"
  xcopy /Y /E /I "%SRC_DIR%contrib\lua_scripts" "%DEPLOY_BIN%\lua_scripts" >nul
)

rem ---- Config templates ----
if not exist "%SRC_DIR%server\etc" mkdir "%SRC_DIR%server\etc"
copy /Y "%SRC_DIR%server\authserver\authserver.conf.dist" "%SRC_DIR%server\etc\" >nul 2>&1
copy /Y "%SRC_DIR%server\worldserver\worldserver.conf.dist" "%SRC_DIR%server\etc\" >nul 2>&1

echo.
echo [OK] Build finished. Binaries: %DEPLOY_BIN%
echo      Next steps: see server\BUILD_WINDOWS.md section 6.
endlocal
