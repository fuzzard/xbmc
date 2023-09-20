#.rst:
# FindCdio
# --------
# Finds the cdio library
#
# This will define the following target:
#
# CDIO::CDIO - the cdio libraries
# CDIO::CDIOPP - the cdio++ library

if(NOT TARGET CDIO::CDIO)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_CDIO libcdio>=0.80 QUIET)
    pkg_check_modules(PC_CDIOPP libcdio++>=2.1.0 QUIET)
  endif()

  find_path(CDIO_INCLUDE_DIR NAMES cdio/cdio.h
                             HINTS ${DEPENDS_PATH}/include ${PC_CDIO_INCLUDEDIR}
                             NO_CACHE)

  find_library(CDIO_LIBRARY NAMES cdio libcdio
                            HINTS ${DEPENDS_PATH}/lib ${PC_CDIO_LIBDIR}
                            NO_CACHE)

  if(DEFINED PC_CDIO_VERSION AND DEFINED PC_CDIOPP_VERSION AND NOT "${PC_CDIO_VERSION}" VERSION_EQUAL "${PC_CDIOPP_VERSION}")
    message(WARNING "Detected libcdio (${PC_CDIO_VERSION}) and libcdio++ (${PC_CDIOPP_VERSION}) version mismatch. libcdio++ will not be used.")
  else()
    find_path(CDIOPP_INCLUDE_DIR NAMES cdio++/cdio.hpp
                                 HINTS ${DEPENDS_PATH}/include ${PC_CDIOPP_INCLUDEDIR} ${CDIO_INCLUDE_DIR}
                                 NO_CACHE)

    set(CDIO_VERSION ${PC_CDIO_VERSION})
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Cdio
                                    REQUIRED_VARS CDIO_LIBRARY CDIO_INCLUDE_DIR
                                    VERSION_VAR CDIO_VERSION)

  if(CDIO_FOUND)
    add_library(CDIO::CDIO UNKNOWN IMPORTED)
    set_target_properties(CDIO::CDIO PROPERTIES
                                     IMPORTED_LOCATION "${CDIO_LIBRARY}"
                                     INTERFACE_INCLUDE_DIRECTORIES "${CDIO_INCLUDE_DIR}")

    if(CDIOPP_INCLUDE_DIR)
      add_library(CDIO::CDIOPP INTERFACE IMPORTED)
      set_target_properties(CDIO::CDIOPP PROPERTIES
                                         INTERFACE_INCLUDE_DIRECTORIES "${CDIOPP_INCLUDE_DIR}")
      target_link_libraries(CDIO::CDIO INTERFACE CDIO::CDIOPP)
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP CDIO::CDIO)
  endif()
endif()
