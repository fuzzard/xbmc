# FindNettle
# -------
# Finds the Nettle library
#
# This will define the following variables:
#
# NETTLE_FOUND - system has Nettle
# NETTLE_INCLUDE_DIRS - the Nettle include directory
# NETTLE_LIBRARIES - the Nettle libraries
# NETTLE_DEFINITIONS - the Nettle compile definitions
#
# and the following imported targets:
#
#   Nettle::Nettle   - The Nettle library

find_package(PkgConfig)

if(PKG_CONFIG_FOUND)
  pkg_check_modules(PC_NETTLE QUIET nettle)
  set(NETTLE_VER ${PC_NETTLE_VERSION})
endif()

find_path(NETTLE_INCLUDE_DIR NAMES nettle/nettle-meta.h
                             PATHS ${PC_NETTLE_INCLUDEDIR})

find_library(NETTLE_LIBRARY NAMES nettle
                              PATHS ${PC_NETTLE_LIBDIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Nettle
                                  REQUIRED_VARS NETTLE_LIBRARY NETTLE_INCLUDE_DIR
                                  VERSION_VAR NETTLE_VER)

if(NETTLE_FOUND)
  set(NETTLE_INCLUDE_DIRS ${NETTLE_FOUND_INCLUDE_DIR})
  set(NETTLE_LIBRARIES ${NETTLE_FOUND_LIBRARY})

  if(NOT TARGET Nettle::Nettle)
    add_library(Nettle::Nettle UNKNOWN IMPORTED)
    set_target_properties(Nettle::Nettle PROPERTIES
                                         IMPORTED_LOCATION "${NETTLE_LIBRARY}"
                                         INTERFACE_COMPILE_OPTIONS "${PC_NETTLE_CFLAGS_OTHER}"
                                         INTERFACE_INCLUDE_DIRECTORIES "${NETTLE_INCLUDE_DIR}")
  endif()
  set(lib_TARGETS Nettle::Nettle ${lib_TARGETS} CACHE STRING "" FORCE)
endif()

mark_as_advanced(NETTLE_INCLUDE_DIR NETTLE_LIBRARY)
