#.rst:
# FindUdfread
# --------
# Finds the udfread library
#
# This will define the following variables::
#
# UDFREAD_FOUND - system has udfread
# UDFREAD_INCLUDE_DIRS - the udfread include directory
# UDFREAD_LIBRARIES - the udfread libraries
# UDFREAD_DEFINITIONS - the udfread definitions

if(ENABLE_INTERNAL_UDFREAD)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC udfread)

  SETUP_BUILD_VARS()

  set(UDFREAD_VERSION ${${MODULE}_VER})

  set(PROJECT_NAME "udfread-build")

  find_program(AUTORECONF autoreconf REQUIRED)

  set(CONFIGURE_COMMAND ${DEPBUILDENV} ${AUTORECONF} -vif
                COMMAND ${DEPBUILDENV} ./configure
                        --enable-static
                        --disable-shared
                        --prefix=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR})

  set(BUILD_COMMAND make)
  set(INSTALL_COMMAND make install)
  set(BUILD_IN_SOURCE 1)

  if(NOT TARGET udfread-build)
    BUILD_DEP_TARGET()
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP udfread-build)
  endif()
  unset(PROJECT_NAME)
else()
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_UDFREAD udfread>=1.0.0 QUIET)
  endif()

  find_path(UDFREAD_INCLUDE_DIR NAMES udfread/udfread.h
                            PATHS ${PC_UDFREAD_INCLUDEDIR})

  find_library(UDFREAD_LIBRARY NAMES udfread libudfread
                           PATHS ${PC_UDFREAD_LIBDIR})

  set(UDFREAD_VERSION ${PC_UDFREAD_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Udfread
                                  REQUIRED_VARS UDFREAD_LIBRARY UDFREAD_INCLUDE_DIR
                                  VERSION_VAR UDFREAD_VERSION)

if(UDFREAD_FOUND)
  set(UDFREAD_LIBRARIES ${UDFREAD_LIBRARY})
  set(UDFREAD_INCLUDE_DIRS ${UDFREAD_INCLUDE_DIR})
  set(UDFREAD_DEFINITIONS -DHAS_UDFREAD=1)

  if(NOT TARGET udfread)
    add_library(udfread UNKNOWN IMPORTED)
    set_target_properties(udfread PROPERTIES
                                  IMPORTED_LOCATION "${UDFREAD_LIBRARY}"
                                  INTERFACE_INCLUDE_DIRECTORIES "${UDFREAD_INCLUDE_DIR}"
                                  INTERFACE_COMPILE_DEFINITIONS "${UDFREAD_DEFINITIONS}")
  endif()

  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP udfread)
endif()

mark_as_advanced(UDFREAD_INCLUDE_DIR UDFREAD_LIBRARY)
