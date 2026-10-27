# check what platform we're on (64-bit or 32-bit), and create a simpler test than CMAKE_SIZEOF_VOID_P
if(CMAKE_SIZEOF_VOID_P MATCHES 8)
    set(PLATFORM 64)
    MESSAGE(STATUS "Detected 64-bit platform")
else()
    set(PLATFORM 32)
    MESSAGE(STATUS "Detected 32-bit platform")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "amd64|x86_64|AMD64")
  set(TRINITY_SYSTEM_PROCESSOR "amd64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm|ARM|aarch)64$")
  set(TRINITY_SYSTEM_PROCESSOR "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm|ARM)$")
  set(TRINITY_SYSTEM_PROCESSOR "arm")
else()
  set(TRINITY_SYSTEM_PROCESSOR "x86")
endif()

# detect MSVC special case of using cmake -A switch (which doesn't set any cross compiling variables)
if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
  set(TRINITY_SYSTEM_PROCESSOR "x86")
elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
  set(TRINITY_SYSTEM_PROCESSOR "amd64")
elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM")
  set(TRINITY_SYSTEM_PROCESSOR "arm")
elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
  set(TRINITY_SYSTEM_PROCESSOR "arm64")
endif()

message(STATUS "Detected ${TRINITY_SYSTEM_PROCESSOR} processor architecture")

if(WIN32)
  # ---- WIN64 support (Windows x64 is the only officially supported build) ----
  # MSVC predefines _WIN64 automatically, but MinGW-w64 does not always do so
  # and some headers/tools rely on it being set explicitly. Enforce it here for
  # every 64-bit Windows toolchain so the core version string reports "(Win64, ...)"
  # (see server/shared/SystemConfig.h) regardless of compiler.
  if(PLATFORM EQUAL 64)
    add_definitions(-D_WIN64)
    message(STATUS "WIN64: 64-bit Windows build, defined -D_WIN64 for all compilers")
  else()
    # The project requires a 64-bit Windows toolchain (MSVC v143 / MinGW-w64 ucrt).
    message(FATAL_ERROR "WIN64: 32-bit (Win32) Windows builds are not supported. Re-configure the build directory with: cmake -G \"Visual Studio 17 2022\" -A x64")
  endif()

  include("${CMAKE_SOURCE_DIR}/cmake/platform/win/settings.cmake")
elseif(UNIX)
  include("${CMAKE_SOURCE_DIR}/cmake/platform/unix/settings.cmake")
endif()
