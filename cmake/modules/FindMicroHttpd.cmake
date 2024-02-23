#.rst:
# FindMicroHttpd
# --------------
# Finds the MicroHttpd library
#
# This will define the following target:
#
#   MicroHttpd::MicroHttpd   - The MicroHttpd library

if(NOT TARGET MicroHttpd::MicroHttpd)
  find_package(PkgConfig)

  if(MicroHttpd_FIND_VERSION)
    if(MicroHttpd_FIND_VERSION_EXACT)
      set(MicroHttpd_FIND_SPEC "=${MicroHttpd_FIND_VERSION_COMPLETE}")
    else()
      set(MicroHttpd_FIND_SPEC ">=${MicroHttpd_FIND_VERSION_COMPLETE}")
    endif()
  endif()

  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_MICROHTTPD libmicrohttpd${MicroHttpd_FIND_SPEC} QUIET)
  endif()

  find_path(MICROHTTPD_INCLUDE_DIR NAMES microhttpd.h
                                   HINTS ${DEPENDS_PATH}/include ${PC_MICROHTTPD_INCLUDEDIR}
                                   ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                                   NO_CACHE)
  find_library(MICROHTTPD_LIBRARY NAMES microhttpd libmicrohttpd
                                  HINTS ${DEPENDS_PATH}/lib ${PC_MICROHTTPD_LIBDIR}
                                  ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                                  NO_CACHE)

  set(MICROHTTPD_VERSION ${PC_MICROHTTPD_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(MicroHttpd
                                    REQUIRED_VARS MICROHTTPD_LIBRARY MICROHTTPD_INCLUDE_DIR
                                    VERSION_VAR MICROHTTPD_VERSION)

  if(MICROHTTPD_FOUND)
    add_library(MicroHttpd::MicroHttpd UNKNOWN IMPORTED)
    set_target_properties(MicroHttpd::MicroHttpd PROPERTIES
                                                 IMPORTED_LOCATION "${MICROHTTPD_LIBRARY}"
                                                 INTERFACE_INCLUDE_DIRECTORIES "${MICROHTTPD_INCLUDE_DIR}"
                                                 INTERFACE_COMPILE_DEFINITIONS "HAS_WEB_SERVER=1;HAS_WEB_INTERFACE=1")

    if(${MICROHTTPD_LIBRARY} MATCHES ".+\.a$" AND PC_MICROHTTPD_STATIC_LIBRARIES)
      list(APPEND MICROHTTPD_LIBRARIES ${PC_MICROHTTPD_STATIC_LIBRARIES})
      # We dont need the explicit lib in INTERFACE_LINK_LIBRARIES
      list(REMOVE_ITEM MICROHTTPD_LIBRARIES "microhttpd")
      set_target_properties(MicroHttpd::MicroHttpd PROPERTIES
                                                   INTERFACE_LINK_LIBRARIES "${MICROHTTPD_LIBRARIES}")
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP MicroHttpd::MicroHttpd)
  endif()
endif()
