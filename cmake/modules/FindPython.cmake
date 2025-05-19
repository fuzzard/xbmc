# FindPython
# --------
# Finds Python3 libraries
#
# This module will search for the required python libraries on the system
# If multiple versions are found, the highest version will be used.
#
# --------
#
# the following variables influence behaviour:
#
# PYTHON_PATH - use external python not found in system paths
#               usage: -DPYTHON_PATH=/path/to/python/lib
# PYTHON_VER - use exact python version, fail if not found
#               usage: -DPYTHON_VER=3.8
#
# --------
#
# This will define the following targets:
#
#   ${APP_NAME_LC}::Python - The Python library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC python3)
  set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_DISABLE_VERSION ON)
  SETUP_BUILD_VARS()

  # for Depends/Windows builds, set search root dir to libdir path
  if(KODI_DEPENDSBUILD
     OR CMAKE_SYSTEM_NAME STREQUAL WINDOWS
     OR CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
    set(Python3_USE_STATIC_LIBS TRUE)
    set(Python3_ROOT_DIR ${libdir})
  endif()

  # Provide root dir to search for Python if provided
  if(PYTHON_PATH)
    set(Python3_ROOT_DIR ${PYTHON_PATH})

    # unset cache var so we can generate again with a different dir (or none) if desired
    unset(PYTHON_PATH CACHE)
  endif()

  # Set specific version of Python to find if provided
  if(PYTHON_VER)
    set(VERSION ${PYTHON_VER})
    set(EXACT_VER "EXACT")

    # unset cache var so we can generate again with a different ver (or none) if desired
    unset(PYTHON_VER CACHE)
  endif()

  find_package(Python3 ${VERSION} ${EXACT_VER} COMPONENTS Development ${SEARCH_QUIET})

  if(Python3_FOUND)
    # We use this all over the place. Maybe it would be nice to keep it as a TARGET property
    # but for now a cached variable will do
    set(PYTHON_VERSION "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}" CACHE INTERNAL "" FORCE)

    add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS Python3::Python)

    if(KODI_DEPENDSBUILD)
      # FFI isnt added to python pkgconfig, so manually add to target link libraries
      # Presumably this is due to our use of MODULE_BUILDTYPE being static and the _ctypes module
      find_library(FFI_LIBRARY ffi REQUIRED)
      set_property(TARGET Python3::Python APPEND PROPERTY
                                                 INTERFACE_LINK_LIBRARIES "${FFI_LIBRARY}")
    endif()

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_COMPILE_DEFINITIONS HAS_PYTHON)

    ADD_TARGET_COMPILE_DEFINITION()
  endif()
endif()
