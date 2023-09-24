#.rst:
# FindLibZip
# -----------
# Finds the LibZip library
#
# This will define the following variables::
#
# LIBZIP_FOUND - system has LibZip
# LIBZIP_INCLUDE_DIRS - the LibZip include directory
# LIBZIP_LIBRARIES - the LibZip libraries
#
# and the following imported targets:
#
#   libzip::zip - The LibZip library

if(NOT TARGET libzip::zip)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC libzip)
  SETUP_BUILD_VARS()

  # Check for existing lib
  find_package(LIBZIP CONFIG QUIET
                      HINTS ${DEPENDS_PATH}/lib/cmake
                      ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  if(NOT LIBZIP_FOUND OR LIBZIP_VERSION VERSION_LESS ${${MODULE}_VER})
    # Check for dependencies
    find_package(GnuTLS MODULE REQUIRED)

    # Eventually we will want Find modules for the following deps
    # bzip2 
    # ZLIB

    set(CMAKE_ARGS -DBUILD_DOC=OFF
                   -DBUILD_EXAMPLES=OFF
                   -DBUILD_REGRESS=OFF
                   -DBUILD_SHARED_LIBS=OFF
                   -DBUILD_TOOLS=OFF)

    set(LIBZIP_VERSION ${${MODULE}_VER})

    BUILD_DEP_TARGET()
  else()
    find_path(LIBZIP_INCLUDE_DIR NAMES zip.h
                                 HINTS ${DEPENDS_PATH}/include
                                 ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG}
                                 NO_CACHE)

    find_library(LIBZIP_LIBRARY NAMES zip
                                HINTS ${DEPENDS_PATH}/lib
                                ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG}
                                NO_CACHE)
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibZip
                                    REQUIRED_VARS LIBZIP_LIBRARY LIBZIP_INCLUDE_DIR
                                    VERSION_VAR LIBZIP_VERSION)

  if(LIBZIP_FOUND)
    if(NOT TARGET libzip::zip)
      add_library(libzip::zip UNKNOWN IMPORTED)

      set_target_properties(libzip::zip PROPERTIES
                                        INTERFACE_INCLUDE_DIRECTORIES "${LIBZIP_INCLUDE_DIR}"
                                        INTERFACE_LINK_LIBRARIES "GnuTLS::GnuTLS"
                                        IMPORTED_LOCATION "${LIBZIP_LIBRARY}")

      if(TARGET libzip)
        add_dependencies(libzip::zip libzip)
      endif()
    else()
      # ToDo: When we correctly import dependencies cmake targets for the following
      # BZip2::BZip2, LibLZMA::LibLZMA, GnuTLS::GnuTLS, Nettle::Nettle,ZLIB::ZLIB
      # For now, we just override
      set_target_properties(libzip::zip PROPERTIES
                                        INTERFACE_LINK_LIBRARIES "GnuTLS::GnuTLS")
    endif()
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libzip::zip)
  else()
    if(LIBZIP_FIND_REQUIRED)
      message(FATAL_ERROR "LibZip not found.")
    endif()
  endif()
endif()
