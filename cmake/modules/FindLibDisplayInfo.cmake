#.rst:
# FindLibDisplayInfo
# -------
# Finds the libdisplay-info library
#
# This will define the following target:
#
#   libdisplayinfo::libdisplayinfo - The libdisplay-info library

if(NOT TARGET libdisplayinfo::libdisplayinfo)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_LIBDISPLAYINFO libdisplay-info QUIET)
  endif()

  find_path(LIBDISPLAYINFO_INCLUDE_DIR NAMES libdisplay-info/edid.h
                                       HINTS ${PC_LIBDISPLAYINFO_INCLUDEDIR}
                                       NO_CACHE)

  find_library(LIBDISPLAYINFO_LIBRARY NAMES display-info
                                      HINTS ${PC_LIBDISPLAYINFO_LIBDIR}
                                      NO_CACHE)

  set(LIBDISPLAYINFO_VERSION ${PC_LIBDISPLAYINFO_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibDisplayInfo
                                    REQUIRED_VARS LIBDISPLAYINFO_LIBRARY LIBDISPLAYINFO_INCLUDE_DIR
                                    VERSION_VAR LIBDISPLAYINFO_VERSION)

  if(LIBDISPLAYINFO_FOUND)
    add_library(libdisplayinfo::libdisplayinfo UNKNOWN IMPORTED)
    set_target_properties(libdisplayinfo::libdisplayinfo PROPERTIES
                                             IMPORTED_LOCATION "${LIBDISPLAYINFO_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${LIBDISPLAYINFO_INCLUDE_DIR}")

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libdisplayinfo::libdisplayinfo)
  endif()
endif()
