#.rst:
# FindLibinput
# --------
# Finds the libinput library
#
# This will define the following target:
#
#   libinput::libinput - The libinput library

if(NOT TARGET libinput::libinput)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_LIBINPUT libinput QUIET)
  endif()

  find_path(LIBINPUT_INCLUDE_DIR NAMES libinput.h
                                 HINTS ${PC_LIBINPUT_INCLUDEDIR}
                                 NO_CACHE)

  find_library(LIBINPUT_LIBRARY NAMES input
                                HINTS ${PC_LIBINPUT_LIBDIR}
                                NO_CACHE)

  set(LIBINPUT_VERSION ${PC_LIBINPUT_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibInput
                                    REQUIRED_VARS LIBINPUT_LIBRARY LIBINPUT_INCLUDE_DIR
                                    VERSION_VAR LIBINPUT_VERSION)

  if(LIBINPUT_FOUND)
    add_library(libinput::libinput UNKNOWN IMPORTED)
    set_target_properties(libinput::libinput PROPERTIES
                                             IMPORTED_LOCATION "${LIBINPUT_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${LIBINPUT_INCLUDE_DIR}")

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libinput::libinput)
  endif()
endif()
