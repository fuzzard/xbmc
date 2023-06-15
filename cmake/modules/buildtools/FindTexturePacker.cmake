#.rst:
# FindTexturePacker
# -----------------
# Finds the TexturePacker
#
# If WITH_TEXTUREPACKER is defined and points to a directory,
# this path will be used to search for the Texturepacker binary
#
#
# This will define the following (imported) targets::
#
#   TexturePacker::TexturePacker::Executable   - The TexturePacker executable participating in build
#   TexturePacker::TexturePacker::Installable  - The TexturePacker executable shipped in the Kodi package

if(NOT TARGET TexturePacker::TexturePacker::Executable)

  include(cmake/scripts/common/ModuleHelpers.cmake)

  # Check for existing TEXTUREPACKER
  find_program(TEXTUREPACKER_EXECUTABLE NAMES "${APP_NAME_LC}-TexturePacker" TexturePacker
                                              "${APP_NAME_LC}-TexturePacker.exe" TexturePacker.exe
                                        HINTS ${NATIVEPREFIX}/bin)

  if(TEXTUREPACKER_EXECUTABLE)
    execute_process(COMMAND "${TEXTUREPACKER_EXECUTABLE}" -version
                    OUTPUT_VARIABLE TEXTUREPACKER_EXECUTABLE_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX MATCH "[^\n]* version [^\n]*" TEXTUREPACKER_EXECUTABLE_VERSION "${TEXTUREPACKER_EXECUTABLE_VERSION}")
    string(REGEX REPLACE ".* version (.*)" "\\1" TEXTUREPACKER_EXECUTABLE_VERSION "${TEXTUREPACKER_EXECUTABLE_VERSION}")
  endif()

  set(MODULE_LC TexturePacker)
  set(LIB_TYPE native)
  SETUP_BUILD_VARS()

  if((NOT TEXTUREPACKER_EXECUTABLE AND NOT WITH_TEXTUREPACKER) OR
     (NOT "${TEXTUREPACKER_EXECUTABLE_VERSION}" VERSION_EQUAL "${TEXTUREPACKER_VER}" AND NOT WITH_TEXTUREPACKER))

    # Override build type detection and always build as release
    set(TEXTUREPACKER_BUILD_TYPE Release)

    set(CMAKE_ARGS -DKODI_SOURCE_DIR=${CMAKE_SOURCE_DIR}
                   -DENABLE_STATIC=1)

    if(NATIVEPREFIX)
      set(INSTALL_DIR "${NATIVEPREFIX}/bin")
      set(TEXTUREPACKER_INSTALL_PREFIX ${NATIVEPREFIX})
      list(APPEND CMAKE_ARGS "-DNATIVEPREFIX=${NATIVEPREFIX}")
    else()
      set(INSTALL_DIR "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/bin")
      set(TEXTUREPACKER_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR})
    endif()

    # Set host build info for buildtool
    if(EXISTS "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
      set(TEXTUREPACKER_TOOLCHAIN_FILE "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
    else()
      if(WIN32)
        # Windows ARCH_DEFINES for store has some things we probably dont want
        # just provide a simple set of defines for all windows host builds
        list(APPEND CMAKE_ARGS -DARCH_DEFINES=TARGET_WINDOWS;WIN32;_CONSOLE;_CRT_SECURE_NO_WARNINGS)
      else()
        list(APPEND CMAKE_ARGS -DARCH_DEFINES=${ARCH_DEFINES})
      endif()
    endif()

    if(WIN32 OR WINDOWS_STORE)
      # Make sure we generate for host arch, not target
      set(TEXTUREPACKER_GENERATOR_PLATFORM CMAKE_GENERATOR_PLATFORM WIN32)
      set(WIN_DISABLE_PROJECT_FLAGS 1)
      set(APP_EXTENSION ".exe")
    endif()

    set(TEXTUREPACKER_SOURCE_DIR ${CMAKE_SOURCE_DIR}/tools/depends/native/TexturePacker/src)
    set(TEXTUREPACKER_EXECUTABLE ${INSTALL_DIR}/TexturePacker${APP_EXTENSION})
    set(TEXTUREPACKER_EXECUTABLE_VERSION ${TEXTUREPACKER_VER})

    set(BUILD_BYPRODUCTS ${TEXTUREPACKER_EXECUTABLE})

    BUILD_DEP_TARGET()

    # Ship TexturePacker only on Linux and FreeBSD
    # Todo: iron on this. need further info on what its purpose is
    if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "Linux")
      # But skip shipping it if build architecture can be executed on host
      # and TEXTUREPACKER_EXECUTABLE is found
      if(NOT (HOST_CAN_EXECUTE_TARGET AND TEXTUREPACKER_EXECUTABLE))
        add_executable(TexturePacker::TexturePacker::Installable ALIAS TexturePacker)
      endif()
    endif()

  else()
    if(WITH_TEXTUREPACKER)
      get_filename_component(_tppath ${WITH_TEXTUREPACKER} ABSOLUTE)
      get_filename_component(_tppath ${_tppath} DIRECTORY)
      find_program(TEXTUREPACKER_EXECUTABLE NAMES "${APP_NAME_LC}-TexturePacker" TexturePacker
                                                  "${APP_NAME_LC}-TexturePacker.exe" TexturePacker.exe
                                            HINTS ${_tppath})

      if(NOT TEXTUREPACKER_EXECUTABLE)
        message(FATAL_ERROR "Could not find 'TexturePacker' executable in ${_tppath} supplied by -DWITH_TEXTUREPACKER")
      endif()
    endif()
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(TexturePacker
                                    REQUIRED_VARS TEXTUREPACKER_EXECUTABLE
                                    VERSION_VAR TEXTUREPACKER_EXECUTABLE_VERSION)

  # Use external TexturePacker executable if found
  if(TEXTUREPACKER_FOUND)
    add_executable(TexturePacker::TexturePacker::Executable IMPORTED GLOBAL)
    set_target_properties(TexturePacker::TexturePacker::Executable PROPERTIES
                                                                   IMPORTED_LOCATION "${TEXTUREPACKER_EXECUTABLE}")
  else()
    message(FATAL_ERROR "Could not find TexturePacker")
  endif()

  mark_as_advanced(TEXTUREPACKER_EXECUTABLE TEXTUREPACKER)
endif()
