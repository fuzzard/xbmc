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

find_package(LIBZIP CONFIG QUIET)

# LibZip dependencies
find_package(BZip2 REQUIRED)
find_package(GnuTLS REQUIRED)
find_package(ZLIB REQUIRED)

# GnuTLS dependency
find_package(Nettle REQUIRED)

if(NOT LIBZIP_FOUND)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC libzip)

  SETUP_BUILD_VARS()

  set(CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
                 -DBUILD_DOC=OFF
                 -DBUILD_EXAMPLES=OFF
                 -DBUILD_REGRESS=OFF
                 -DBUILD_SHARED_LIBS=OFF
                 -DENABLE_LZMA=OFF
                 -DBUILD_TOOLS=OFF)

  BUILD_DEP_TARGET()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibZip
                                    REQUIRED_VARS LIBZIP_LIBRARY LIBZIP_INCLUDE_DIR
                                    VERSION_VAR LIBZIP_VER)
endif()

if(LIBZIP_FOUND)
  if(NOT TARGET libzip::zip)
    add_library(libzip::zip UNKNOWN IMPORTED)
    set_target_properties(libzip::zip PROPERTIES
                                 IMPORTED_LOCATION "${LIBZIP_LIBRARY}"
                                 INTERFACE_INCLUDE_DIRECTORIES "${LIBZIP_INCLUDE_DIR}")
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libzip)

  endif()
  set(lib_TARGETS libzip::zip ${lib_TARGETS} CACHE STRING "" FORCE)
endif()

mark_as_advanced(LIBZIP_INCLUDE_DIR LIBZIP_LIBRARY)
