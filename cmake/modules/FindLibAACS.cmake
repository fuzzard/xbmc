#.rst:
# FindLibAACS
# --------
# Finds the Libaacs library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::LibAACS   - The libaacs library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_LIBAACS libaacs QUIET)
  endif()

  find_library(LIBAACS_LIBRARY NAMES aacs
                               HINTS ${PC_LIBAACS_LIBDIR}
                               NO_CACHE)

  set(LIBAACS_VERSION ${PC_LIBAACS_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibAACS
                                    REQUIRED_VARS LIBAACS_LIBRARY
                                    VERSION_VAR LIBAACS_VERSION)

  if(LibAACS_FOUND)
    add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} UNKNOWN IMPORTED)
    set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                     IMPORTED_LOCATION "${LIBAACS_LIBRARY}")

  else()
    if(LibAACS_FIND_REQUIRED)
      message(FATAL_ERROR "LibAACS library was not found.")
    endif()
  endif()
endif()
