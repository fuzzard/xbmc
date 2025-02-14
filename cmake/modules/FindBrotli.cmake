#.rst:
# FindBrotli
# ----------
# Finds the Brotli library
#
# This will define the following target ALIAS:
#
#   brotli::brotli   - The Brotli library
#
# The following IMPORTED targets are made
#
#   brotli::brotlicommon - The brotlicommon library
#   brotli::brotlidec - The brotlidec library
#

if(NOT TARGET brotli::brotli)

  macro(buildbrotli)

    set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/01-all-disable-exe.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/02-all-cmake-install-config.patch")

    generate_patchcommand("${patches}")

    set(CMAKE_ARGS -DBUILD_SHARED_LIBS=OFF
                   -DBROTLI_DISABLE_TESTS=ON
                   -DBROTLI_DISABLE_EXE=ON)

    BUILD_DEP_TARGET()

    string(REGEX REPLACE "^.*\\." "" _LIBEXT ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BYPRODUCT})
    set(BROTLICOMMON_LIBRARY "${DEP_LOCATION}/lib/libbrotlicommon.${_LIBEXT}")

    set(BROTLIDEC_LIBRARY "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY}")

  endmacro()

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC brotli)

  SETUP_BUILD_VARS()

  # Search for cmake config. Suitable for all platforms including windows
  find_package(brotli CONFIG
                      HINTS ${DEPENDS_PATH}/lib/cmake
                      ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  # Check for existing Brotli. If version >= BROTLI-VERSION file version, dont build
  if(brotli2_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND Brotli_FIND_REQUIRED)
    # Build lib
    buildbrotli()
  else()


    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND AND NOT (WIN32 OR WINDOWSSTORE))
      pkg_check_modules(BROTLICOMMON libbrotlicommon QUIET)
      # First item is the full path of the library file found
      # pkg_check_modules does not populate a variable of the found library explicitly
      list(GET BROTLICOMMON_LINK_LIBRARIES 0 BROTLICOMMON_LIBRARY)
  
      pkg_check_modules(BROTLIDEC libbrotlidec QUIET)
      # First item is the full path of the library file found
      # pkg_check_modules does not populate a variable of the found library explicitly
      list(GET BROTLIDEC_LINK_LIBRARIES 0 BROTLIDEC_LIBRARY)
  
      set(BROTLI_INCLUDE_DIR ${BROTLICOMMON_INCLUDEDIR})
      set(BROTLI_VERSION ${BROTLICOMMON_VERSION})
    else()
      find_path(BROTLI_INCLUDE_DIR NAMES brotli/decode.h
                                   HINTS ${DEPENDS_PATH}/include ${BROTLICOMMON_INCLUDEDIR}
                                   ${${CORE_PLATFORM_LC}_SEARCH_CONFIG})
      find_library(BROTLICOMMON_LIBRARY NAMES brotlicommon
                                        HINTS ${DEPENDS_PATH}/lib ${BROTLICOMON_LIBDIR}
                                        ${${CORE_PLATFORM_LC}_SEARCH_CONFIG})
  
      find_library(BROTLIDEC_LIBRARY NAMES brotlidec
                                     HINTS ${DEPENDS_PATH}/lib ${BROTLIDEC_LIBDIR}
                                     ${${CORE_PLATFORM_LC}_SEARCH_CONFIG})
    endif()
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(BROTLI)
  unset(BROTLI_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Brotli
                                    REQUIRED_VARS BROTLICOMMON_LIBRARY BROTLIDEC_LIBRARY BROTLI_INCLUDE_DIR
                                    VERSION_VAR BROTLI_VERSION)

  if(BROTLI_FOUND)
    if((TARGET brotli::brotlicommon AND TARGET brotli::brotlidec)  AND NOT TARGET brotli)
      add_library(brotli::brotli ALIAS brotli::brotlidec)
    else()
      add_library(brotli::brotli UNKNOWN IMPORTED)
      set_target_properties(brotli::brotlicommon PROPERTIES
                                                 IMPORTED_LOCATION "${BROTLICOMMON_LIBRARY}"
                                                 INTERFACE_INCLUDE_DIRECTORIES "${BROTLI_INCLUDE_DIR}")
  
      add_library(brotli::BrotliDec UNKNOWN IMPORTED)
      set_target_properties(brotli::brotlidec PROPERTIES
                                              IMPORTED_LOCATION "${BROTLIDEC_LIBRARY}"
                                              INTERFACE_LINK_LIBRARIES brotli::brotlicommon
                                              INTERFACE_INCLUDE_DIRECTORIES "${BROTLI_INCLUDE_DIR}")
  
      add_library(brotli::brotli ALIAS brotli::brotlidec)

    endif()

    if(TARGET brotli)
      add_dependencies(brotli::brotli brotli)
    endif()

    # Add internal build target when a Multi Config Generator is used
    # We cant add a dependency based off a generator expression for targeted build types,
    # https://gitlab.kitware.com/cmake/cmake/-/issues/19467
    # therefore if the find heuristics only find the library, we add the internal build
    # target to the project to allow user to manually trigger for any build type they need
    # in case only a specific build type is actually available (eg Release found, Debug Required)
    # This is mainly targeted for windows who required different runtime libs for different
    # types, and they arent compatible
    if(_multiconfig_generator)
      if(NOT TARGET brotli)
        buildbrotli()
        set_target_properties(brotli PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
      add_dependencies(build_internal_depends brotli)
    endif()

  else()
    if(Brotli_FIND_REQUIRED)
      message(FATAL_ERROR "Brotli libraries were not found.")
    endif()
  endif()
endif()
