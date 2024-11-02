#.rst:
# FindLibBDPlus
# --------
# Finds the Libbdplus library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::LibBDPlus   - The libbdplus library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_LIBBDPLUS libbdplus QUIET)
  endif()

  find_library(LIBBDPLUS_LIBRARY NAMES bdplus
                                 HINTS ${PC_LIBBDPLUS_LIBDIR}
                                 NO_CACHE)

  set(LIBBDPLUS_VERSION ${PC_LIBBDPLUS_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibBDPlus
                                    REQUIRED_VARS LIBBDPLUS_LIBRARY
                                    VERSION_VAR LIBBDPLUS_VERSION)

  if(LibBDPlus_FOUND)
    add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} UNKNOWN IMPORTED)
    set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                     IMPORTED_LOCATION "${LIBBDPLUS_LIBRARY}")

  else()
    if(LibBDPlus_FIND_REQUIRED)
      message(FATAL_ERROR "LibBDPlus library was not found.")
    endif()
  endif()
endif()
