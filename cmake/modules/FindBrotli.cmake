#.rst:
# FindBrotli
# ----------
# Finds the Brotli library
#
# This will define the following target ALIAS:
#
#   LIBRARY::Brotli   - The Brotli library
#
# The following IMPORTED targets are made
#
#   brotli::brotlicommon - The brotlicommon library
#   brotli::brotlidec - The brotlidec library
#

if(NOT TARGET LIBRARY::${CMAKE_FIND_PACKAGE_NAME})

  macro(buildmacroBrotli)

    set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/01-all-disable-exe.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/02-all-cmake-install-config.patch")

    generate_patchcommand("${patches}")

    set(CMAKE_ARGS -DBUILD_SHARED_LIBS=OFF
                   -DBROTLI_DISABLE_TESTS=ON
                   -DBROTLI_DISABLE_EXE=ON)

    BUILD_DEP_TARGET()

    # Retrieve suffix of platform byproduct to apply to second brotli library
    string(REGEX REPLACE "^.*\\." "" _LIBEXT ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BYPRODUCT})
    if(NOT (WIN32 OR WINDOWS_STORE))
      set(_PREFIX "lib")
    endif()

    set(BROTLICOMMON_LIBRARY_RELEASE "${DEP_LOCATION}/lib/${_PREFIX}brotlicommon.${_LIBEXT}")
    set(BROTLIDEC_LIBRARY_RELEASE "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY}")

    # Todo: debug postfix libs for windows
    #       Will require patching nghttp2, as they do not use debug postfix for differentiation

  endmacro()

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC brotli)

  SETUP_BUILD_VARS()

  SETUP_FIND_SPECS()

  SEARCH_EXISTING_PACKAGES()

  # Check for existing Brotli. If version >= BROTLI-VERSION file version, dont build
  if(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND Brotli_FIND_REQUIRED)
    message(STATUS "Building ${CMAKE_FIND_PACKAGE_NAME} (Version: ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})")
    cmake_language(EVAL CODE "
      buildmacro${CMAKE_FIND_PACKAGE_NAME}()
    ")
  endif()

  if(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_FOUND)
    if((TARGET brotli::brotlicommon AND TARGET brotli::brotlidec) AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS brotli::brotlidec)
    elseif(TARGET PkgConfig::brotlicommon AND TARGET PkgConfig::brotlidec AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::brotlidec)
    else()
      add_library(LIBRARY::brotlicommon UNKNOWN IMPORTED)
      set_target_properties(LIBRARY::brotlicommon PROPERTIES
                                                  IMPORTED_LOCATION "${BROTLICOMMON_LIBRARY}"
                                                  INTERFACE_INCLUDE_DIRECTORIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR}")
  
      add_library(LIBRARY::brotlidec UNKNOWN IMPORTED)
      set_target_properties(LIBRARY::brotlidec PROPERTIES
                                               IMPORTED_LOCATION "${BROTLIDEC_LIBRARY}"
                                               INTERFACE_LINK_LIBRARIES LIBRARY::brotlicommon
                                               INTERFACE_INCLUDE_DIRECTORIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR}")
  
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS LIBRARY::brotlidec)

      add_dependencies(LIBRARY::brotlidec ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})

      # We are building as a requirement, so set LIB_BUILD property to allow calling
      # modules to know we will be building, and they will want to rebuild as well.
      # Property must be set on actual TARGET and not the ALIAS
      set_target_properties(${aliased_target} PROPERTIES LIB_BUILD ON)
    endif()

    ADD_MULTICONFIG_BUILDMACRO()
  else()
    if(Brotli_FIND_REQUIRED)
      message(FATAL_ERROR "Brotli libraries were not found.")
    endif()
  endif()
endif()
