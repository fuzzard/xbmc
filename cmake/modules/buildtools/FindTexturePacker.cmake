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
  if(NOT KODI_DEPENDSBUILD)
    get_filename_component(_tppath "${NATIVEPREFIX}/bin" ABSOLUTE)
    find_program(TEXTUREPACKER_EXECUTABLE NAMES "${APP_NAME_LC}-TexturePacker" TexturePacker
                                          HINTS ${_tppath})

    add_executable(TexturePacker::TexturePacker::Executable IMPORTED GLOBAL)
    set_target_properties(TexturePacker::TexturePacker::Executable PROPERTIES
                                          IMPORTED_LOCATION "${TEXTUREPACKER_EXECUTABLE}")
    message(STATUS "External TexturePacker for KODI_DEPENDSBUILD will be executed during build: ${TEXTUREPACKER_EXECUTABLE}")
  elseif(WIN32)
    get_filename_component(_tppath "${DEPENDENCIES_DIR}/tools/TexturePacker" ABSOLUTE)
    find_program(TEXTUREPACKER_EXECUTABLE NAMES "${APP_NAME_LC}-TexturePacker.exe" TexturePacker.exe
                                          HINTS ${_tppath})

    add_executable(TexturePacker::TexturePacker::Executable IMPORTED GLOBAL)
    set_target_properties(TexturePacker::TexturePacker::Executable PROPERTIES
                                          IMPORTED_LOCATION "${TEXTUREPACKER_EXECUTABLE}")
    message(STATUS "External TexturePacker for WIN32 will be executed during build: ${TEXTUREPACKER_EXECUTABLE}")
  else()
    if(WITH_TEXTUREPACKER)
      get_filename_component(_tppath ${WITH_TEXTUREPACKER} ABSOLUTE)
      get_filename_component(_tppath ${_tppath} DIRECTORY)
      find_program(TEXTUREPACKER_EXECUTABLE NAMES "${APP_NAME_LC}-TexturePacker" TexturePacker
                                          HINTS ${_tppath})

      # Use external TexturePacker executable if found
      if(TEXTUREPACKER_EXECUTABLE)
        add_executable(TexturePacker::TexturePacker::Executable IMPORTED GLOBAL)
        set_target_properties(TexturePacker::TexturePacker::Executable PROPERTIES
                                          IMPORTED_LOCATION "${TEXTUREPACKER_EXECUTABLE}")
        message(STATUS "Found external TexturePacker: ${TEXTUREPACKER_EXECUTABLE}")
      else()
        # Warn about external TexturePacker supplied but not fail fatally
        # because we might have internal TexturePacker executable built
        # and unset TEXTUREPACKER_EXECUTABLE variable
        message(WARNING "Could not find '${APP_NAME_LC}-TexturePacker' or 'TexturePacker' executable in ${_tppath} supplied by -DWITH_TEXTUREPACKER. Make sure the executable file name matches these names!")
      endif()
    endif()

    # Ship TexturePacker only on Linux and FreeBSD
    if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "Linux")
      set(INTERNAL_TEXTUREPACKER_INSTALLABLE TRUE)
    endif()

    # Use it during build if build architecture can be executed on host
    # and TEXTUREPACKER_EXECUTABLE is not found
    #if(HOST_CAN_EXECUTE_TARGET AND NOT TEXTUREPACKER_EXECUTABLE)
      set(INTERNAL_TEXTUREPACKER_EXECUTABLE TRUE)
    #endif()

    # Build and install internal TexturePacker if needed
    if (INTERNAL_TEXTUREPACKER_EXECUTABLE OR INTERNAL_TEXTUREPACKER_INSTALLABLE)

      include(${CMAKE_SOURCE_DIR}/cmake/scripts/common/ModuleHelpers.cmake)
      set(MODULE TEXTUREPACKER)

      unset(BUILD_NAME)
      unset(NATIVETARGET)
      unset(INSTALL_DIR)
      unset(CMAKE_ARGS)
      unset(PATCH_COMMAND)
      unset(CONFIGURE_COMMAND)
      unset(BUILD_COMMAND)
      unset(INSTALL_COMMAND)
      unset(BUILD_IN_SOURCE)
      unset(BUILD_BYPRODUCTS)

      if(NATIVEPREFIX)
        set(INSTALL_DIR "${NATIVEPREFIX}/bin")
        set(TEXTUREPACKER_INSTALL_PREFIX ${NATIVEPREFIX})
      else()
        set(INSTALL_DIR "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/bin")
        set(TEXTUREPACKER_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR})
      endif()

      if(CMAKE_GENERATOR STREQUAL Xcode)
        set(TEXTUREPACKER_GENERATOR CMAKE_GENERATOR "Unix Makefiles")
      endif()

      # Set host build info for buildtool
      if(EXISTS "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
        set(TEXTUREPACKER_TOOLCHAIN_FILE "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
      elseif(WIN32 OR WINDOWS_STORE)
        set(TEXTUREPACKER_GENERATOR_PLATFORM CMAKE_GENERATOR_PLATFORM ${HOSTTOOLSET})
        set(TEXTUREPACKER_GENERATOR CMAKE_GENERATOR "${CMAKE_GENERATOR}")
      endif()

      set(BUILD_NAME texturepacker_build)

      set(TEXTUREPACKER_SOURCE_DIR "${CMAKE_SOURCE_DIR}/tools/depends/native/TexturePacker")
      set(TEXTUREPACKER_EXECUTABLE ${INSTALL_DIR}/${APP_NAME_LC}-TexturePacker CACHE INTERNAL "TexturePacker Executable")
      set(BUILD_BYPRODUCTS ${TEXTUREPACKER_EXECUTABLE})

      set(CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
                     -DCMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}
                     -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake/modules/buildtools/libraries)

      BUILD_DEP_TARGET()

      unset(MODULE)
      message(STATUS "Building internal TexturePacker")
    endif()

    if(INTERNAL_TEXTUREPACKER_INSTALLABLE)
      add_executable(TexturePacker::TexturePacker::Installable IMPORTED)
      set_target_properties(TexturePacker::TexturePacker::Installable PROPERTIES
                                                                      IMPORTED_LOCATION "${TEXTUREPACKER_EXECUTABLE}")
      add_dependencies(TexturePacker::TexturePacker::Installable texturepacker_build)
      message(STATUS "Shipping internal TexturePacker")
    endif()

    if(INTERNAL_TEXTUREPACKER_EXECUTABLE)
      add_executable(TexturePacker::TexturePacker::Executable IMPORTED)
      set_target_properties(TexturePacker::TexturePacker::Executable PROPERTIES
                                                                     IMPORTED_LOCATION "${TEXTUREPACKER_EXECUTABLE}")
      add_dependencies(TexturePacker::TexturePacker::Executable texturepacker_build)
      message(STATUS "Internal TexturePacker will be executed during build")
    else()
      message(STATUS "External TexturePacker will be executed during build: ${TEXTUREPACKER_EXECUTABLE}")

      include(FindPackageHandleStandardArgs)
      find_package_handle_standard_args(TexturePacker DEFAULT_MSG TEXTUREPACKER_EXECUTABLE)
    endif()

    mark_as_advanced(INTERNAL_TEXTUREPACKER_EXECUTABLE INTERNAL_TEXTUREPACKER_INSTALLABLE TEXTUREPACKER)
  endif()
endif()
