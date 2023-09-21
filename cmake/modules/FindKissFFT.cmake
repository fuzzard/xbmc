#.rst:
# FindKissFFT
# ------------
# Finds the KissFFT as a Fast Fourier Transformation (FFT) library
#
# This will define the following target:
#
#   KissFFT::KissFFT   - The KissFFT library

if(NOT TARGET kissfft::kissfft)

  # Build lib macro
  # ToDo: WIN add patch for postfix_debug
  macro(buildKissFFT)
    set(KISSFFT_VERSION ${${MODULE}_VER})

    # manual build name required as kissfft cmake config can generate a target with the name kissfft
    set(BUILD_NAME build-kissfft)

    set(CMAKE_ARGS -DKISSFFT_STATIC=ON
                   -DKISSFFT_TOOLS=OFF
                   -DKISSFFT_PKGCONFIG=OFF
                   -DCMAKE_INSTALL_LIBDIR=${DEPENDS_PATH}/lib
                   -DCMAKE_INSTALL_INCLUDEDIR=${DEPENDS_PATH}/include
                   -DKISSFFT_TEST=OFF)

    BUILD_DEP_TARGET()
  endmacro()

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC kissfft)

  SETUP_BUILD_VARS()

  # internal build we always expect STATIC
  if(ENABLE_INTERNAL_KISSFFT OR KODI_DEPENDSBUILD)
    set(KISSFFT_COMPONENT_SEARCH COMPONENTS STATIC)
  endif()

  # Check for existing kissfft
  find_package(kissfft CONFIG QUIET
                              ${KISSFFT_COMPONENT_SEARCH}
                              HINTS ${DEPENDS_PATH}/lib/cmake
                              ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  # Check for existing kissfft. If version >= KISSFFT-VERSION file version, dont build
  # A corner case, but if a linux/freebsd user WANTS to build internal, build anyway
  # Windows build always as we dont patch postfix for debug currently
  if((kissfft_VERSION VERSION_LESS ${${MODULE}_VER} AND ENABLE_INTERNAL_KISSFFT) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_KISSFFT) OR
     WIN32)
    # Call build macro
    buildKissFFT()
  else()
    if(NOT TARGET kissfft::kissfft-float)
      find_package(PkgConfig)
      if(PKG_CONFIG_FOUND)
        pkg_check_modules(PC_KISSFFT kissfft QUIET)
      endif()

      find_path(KISSFFT_INCLUDE_DIR NAMES kissfft/kiss_fft.h kissfft/kiss_fftr.h
                                    HINTS ${PC_KISSFFT_INCLUDEDIR}
                                    NO_CACHE)
      find_library(KISSFFT_LIBRARY NAMES kissfft-float kissfft-int32 kissfft-int16 kissfft-simd
                                   HINTS ${PC_KISSFFT_LIBDIR}
                                   NO_CACHE)
    else()
      get_target_property(_KISSFFT_CONFIGURATIONS kissfft::kissfft-float IMPORTED_CONFIGURATIONS)

      foreach(_kissfft_config IN LISTS _KISSFFT_CONFIGURATIONS)
        # Some non standard config (eg None on Debian)
        # Just set to RELEASE var so select_library_configurations can continue to work its magic
        string(TOUPPER ${_kissfft_config} _kissfft_config_UPPER)
        if((NOT ${_kissfft_config_UPPER} STREQUAL "RELEASE") AND
           (NOT ${_kissfft_config_UPPER} STREQUAL "DEBUG"))
          get_target_property(KISSFFT_LIBRARY_RELEASE kissfft::kissfft-float IMPORTED_LOCATION_${_kissfft_config_UPPER})
        else()
          get_target_property(KISSFFT_LIBRARY_${_kissfft_config_UPPER} kissfft::kissfft-float IMPORTED_LOCATION_${_kissfft_config_UPPER})
        endif()
      endforeach()

      # Need this, as we may only get the existing TARGET from system and not build or use pkg-config
      get_target_property(KISSFFT_INCLUDE_DIR kissfft::kissfft-float INTERFACE_INCLUDE_DIRECTORIES)
    endif()
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(KISSFFT)
  # Force unset _LIBRARIES as we do not want them due to our old macro usage that
  # relied on variables to populate data instead of TARGETS
  unset(KISSFFT_LIBRARIES)

  # Check if all REQUIRED_VARS are satisfied and set KISSFFT_FOUND
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(KissFFT REQUIRED_VARS KISSFFT_LIBRARY KISSFFT_INCLUDE_DIR
                                            VERSION_VAR KISSFFT_VERSION)

  if(KISSFFT_FOUND)
    if(TARGET kissfft::kissfft-float AND NOT TARGET build-kissfft)
      # Found target and not building internal
      add_library(kissfft::kissfft ALIAS kissfft::kissfft-float)
    else()
      # Either pkg-config or internal build, we manually set
      add_library(kissfft::kissfft UNKNOWN IMPORTED)
      set_target_properties(kissfft::kissfft PROPERTIES
                                             IMPORTED_LOCATION "${KISSFFT_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${KISSFFT_INCLUDE_DIR}")

      if(TARGET build-kissfft)
        add_dependencies(kissfft::kissfft build-kissfft)
      else()
        # Add internal build target when a Multi Config Generator is used
        # We cant add a dependency based off a generator expression for targeted build types,
        # https://gitlab.kitware.com/cmake/cmake/-/issues/19467
        # therefore if the find heuristics only find the library, we add the internal build
        # target to the project to allow user to manually trigger for any build type they need
        # in case only a specific build type is actually available (eg Release found, Debug Required)
        # This is mainly targeted for windows who required different runtime libs for different
        # types, and they arent compatible
        if(_multiconfig_generator)
          buildKissFFT()
        endif()
      endif()
    endif()
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP kissfft::kissfft)
  endif()
endif()
