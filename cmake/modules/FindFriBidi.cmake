#.rst:
# FindFribidi
# -----------
# Finds the GNU FriBidi library
#
# This will define the following target:
#
#   FriBidi::FriBidi   - The FriBidi library

if(NOT TARGET FriBidi::FriBidi)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_FRIBIDI fribidi QUIET IMPORTED_TARGET)
  endif()

  find_path(FRIBIDI_INCLUDE_DIR NAMES fribidi.h
                                PATH_SUFFIXES fribidi
                                HINTS ${DEPENDS_PATH}/include ${PC_FRIBIDI_INCLUDEDIR}
                                ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                                NO_CACHE)
  find_library(FRIBIDI_LIBRARY NAMES fribidi libfribidi
                               HINTS ${DEPENDS_PATH}/lib ${PC_FRIBIDI_LIBDIR}
                               ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                               NO_CACHE)

  set(FRIBIDI_VERSION ${PC_FRIBIDI_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(FriBidi
                                    REQUIRED_VARS FRIBIDI_LIBRARY FRIBIDI_INCLUDE_DIR
                                    VERSION_VAR FRIBIDI_VERSION)

  if(FRIBIDI_FOUND)
    if(TARGET PkgConfig::PC_FRIBIDI)
      add_library(FriBidi::FriBidi ALIAS PkgConfig::PC_FRIBIDI)
    else()
      add_library(FriBidi::FriBidi UNKNOWN IMPORTED)
      set_target_properties(FriBidi::FriBidi PROPERTIES
                                             IMPORTED_LOCATION "${FRIBIDI_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${FRIBIDI_INCLUDE_DIR}")
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP FriBidi::FriBidi)
  endif()
endif()
