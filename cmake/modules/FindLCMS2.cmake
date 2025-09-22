#.rst:
# FindLCMS2
# -----------
# Finds the LCMS Color Management library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::LCMS2 - The LCMS Color Management library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  include(cmake/scripts/common/ModuleHelpers.cmake)

  macro(buildmacroLCMS2)
    # Build tools
    find_package(Meson REQUIRED)
    find_package(Ninja REQUIRED)

    # Dependencies
    find_package(libjpeg-turbo)

    # Todo: windows probably needs a cross file for CI
    if(EXISTS ${DEPENDS_PATH}/share/cross-file.meson)
      set(CROSS_FILE --cross-file=${DEPENDS_PATH}/share/cross-file.meson)
    endif()

    set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env --modify PATH=path_list_prepend:${NATIVEPREFIX}/bin
                          ${MESON_EXECUTABLE} setup ./build
                          --cmake-prefix-path=['${DEPENDS_PATH}/lib/cmake']
                          --prefix=${DEPENDS_PATH}
                          --libdir=lib
                          --buildtype=release
                          -Ddefault_library=static
                          -Dtests=disabled
                          ${CROSS_FILE})

    set(BUILD_COMMAND ${NINJA_EXECUTABLE} -C ./build -v)
    set(INSTALL_COMMAND ${NINJA_EXECUTABLE} -C ./build -v install)
    set(BUILD_IN_SOURCE 1)

    BUILD_DEP_TARGET()

  endmacro()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC lcms2)

  SETUP_BUILD_VARS()

  SETUP_FIND_SPECS()

  SEARCH_EXISTING_PACKAGES()

  # Demo for cmake_pkg_config usage.
  # Ideally we want to extract this into SEARCH_EXISTING_PACKAGES to allow using
  # pkgconfig files on windows platforms to reduce the need for our custom cmake build
  # scripts for libs
  if(WIN32 OR WINDOWS_STORE)
    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.31)
      # Todo: cmake 4.1
      #       cmake_pkg_config(IMPORT <package> [<version>] [...])

      # create manual target from variables
      cmake_pkg_config(EXTRACT ${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME_PC} ${PC_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC}
                               PC_LIBDIR ${DEPENDS_PATH}/lib/pkgconfig;${DEPENDS_PATH}/share/pkgconfig
                               ALLOW_SYSTEM_INCLUDES false
                               ALLOW_SYSTEM_LIBS false)

      if(VERBOSE)
        print_cmake_pkg_config_variables()
      endif()

      if(NOT "${CMAKE_PKG_CONFIG_NAME}" STREQUAL "")
        # Create scoped variables of cmake_pkg_config(EXTRACT) call and clean
        # global level variables created by the call to not pollute next usage
        scope_cmake_pkg_config_variables()
        unset_cmake_pkg_config()

        # Strip -I to allow paths ready for cmake TARGET
        foreach(_include_path IN LISTS ${CMAKE_FIND_PACKAGE_NAME}_PKG_CONFIG_INCLUDES)
          string(REPLACE "-I" "" _include_out_path ${_include_path})
          list(APPEND _pkg_include_list ${_include_out_path})
        endforeach()
        set(${CMAKE_FIND_PACKAGE_NAME}_PKG_CONFIG_INCLUDES ${_pkg_include_list})
  
        # Minimal target
        # Todo: *_PKG_CONFIG_COMPILE_OPTIONS = INTERFACE_COMPILE_DEFINITIONS
        #       *_PKG_CONFIG_LINK_OPTIONS = INTERFACE_LINK_OPTIONS
        add_library(PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} UNKNOWN IMPORTED)
        set_target_properties(PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} PROPERTIES
                                                                                   IMPORTED_LINK_INTERFACE_LIBRARIES "${${CMAKE_FIND_PACKAGE_NAME}_PKG_CONFIG_LIBNAMES}"
                                                                                   INTERFACE_INCLUDE_DIRECTORIES "${${CMAKE_FIND_PACKAGE_NAME}_PKG_CONFIG_INCLUDES}")

        set(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_VERSION ${${CMAKE_FIND_PACKAGE_NAME}_PKG_CONFIG_VERSION})
        set(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_FOUND 1)
      endif()
    endif()
  endif()

  if((${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND ENABLE_INTERNAL_LCMS2) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_LCMS2))
    cmake_language(EVAL CODE "
      buildmacro${CMAKE_FIND_PACKAGE_NAME}()
    ")
  endif()

  if(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_FOUND)

    if(TARGET PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME})
    else()
      SETUP_BUILD_TARGET()
      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
    endif()

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_COMPILE_DEFINITIONS HAVE_LCMS2 
                                                                 CMS_NO_REGISTER_KEYWORD)

    ADD_TARGET_COMPILE_DEFINITION()

    ADD_MULTICONFIG_BUILDMACRO()
  else()
    if(LCMS2_FIND_REQUIRED)
      message(FATAL_ERROR "LCMS2 libraries were not found.")
    endif()
  endif()
endif()
