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

if(NOT LIBZIP_FOUND)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC libzip)

  SETUP_BUILD_VARS()

  set(CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
                 -DBUILD_DOC=OFF
                 -DBUILD_EXAMPLES=OFF
                 -DBUILD_REGRESS=OFF
                 -DBUILD_SHARED_LIBS=OFF
                 -DBUILD_TOOLS=OFF)

  BUILD_DEP_TARGET()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibZip
                                  REQUIRED_VARS LIBZIP_LIBRARY LIBZIP_INCLUDE_DIR
                                  VERSION_VAR LIBZIP_VER)

if(LIBZIP_FOUND)
  set(LIBZIP_LIBRARIES ${LIBZIP_LIBRARY})
  set(LIBZIP_INCLUDE_DIRS ${LIBZIP_INCLUDE_DIR})

  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libzip)
endif()

mark_as_advanced(LIBZIP_INCLUDE_DIR LIBZIP_LIBRARY)
