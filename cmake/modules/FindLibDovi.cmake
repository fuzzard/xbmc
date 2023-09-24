# FindDovi
# -------
# Finds the libdovi library
#
# This will define the following target:
#
#   libdovi::libdovi - The libdovi library

if(NOT TARGET libdovi::libdovi)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_LIBDOVI libdovi QUIET)
  endif()

  find_library(LIBDOVI_LIBRARY NAMES dovi libdovi
                               HINTS ${DEPENDS_PATH}/lib ${PC_LIBDOVI_LIBDIR}
                               ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                               NO_CACHE)
  find_path(LIBDOVI_INCLUDE_DIR NAMES libdovi/rpu_parser.h
                                HINTS ${DEPENDS_PATH}/include ${PC_LIBDOVI_INCLUDEDIR}
                                ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                                NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibDovi
                                    REQUIRED_VARS LIBDOVI_LIBRARY LIBDOVI_INCLUDE_DIR)

  if(LIBDOVI_FOUND)
    add_library(libdovi::libdovi UNKNOWN IMPORTED)
    set_target_properties(libdovi::libdovi PROPERTIES
                                             IMPORTED_LOCATION "${LIBDOVI_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${LIBDOVI_INCLUDE_DIR}"
                                             INTERFACE_COMPILE_DEFINITIONS HAVE_LIBDOVI=1)

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libdovi::libdovi)
  endif()
endif()
