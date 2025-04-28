#.rst:
# FindCEC
# -------
# Finds the libCEC library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::CEC - The libCEC library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})
  include(cmake/scripts/common/ModuleHelpers.cmake)

  macro(buildCEC)

    find_package(P8Platform REQUIRED ${SEARCH_QUIET})

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})

    set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/001-all-cmakelists.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/002-all-libceccmakelists.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/003-all-remove_git_info.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/004-all-PR674.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/005-all-PR675-1.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/006-all-PR675-2.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/007-all-cmake-version.patch")

    generate_patchcommand("${patches}")

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB TRUE)

    if(CORE_SYSTEM_NAME STREQUAL "osx")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LOCATION_POSTFIX "dylib")
    endif()

    set(CMAKE_ARGS -DBUILD_SHARED_LIBS=ON
                   -DSKIP_PYTHON_WRAPPER=ON
                   -DDISABLE_BUILDINFO=ON
                   -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON)

    BUILD_DEP_TARGET()

    if(CORE_SYSTEM_NAME STREQUAL "osx")
      find_program(INSTALL_NAME_TOOL NAMES install_name_tool)
      add_custom_command(TARGET ${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} POST_BUILD
                         COMMAND ${INSTALL_NAME_TOOL} -id ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY} ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY})
    endif()

    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} LIBRARY::P8Platform)
  endmacro()

  # If there is a potential this library can be built internally
  # Check its dependencies to allow forcing this lib to be built if one of its
  # dependencies requires being rebuilt
  if(ENABLE_INTERNAL_CEC)
    # Dependency list of this find module for an INTERNAL build
    set(${CMAKE_FIND_PACKAGE_NAME}_DEPLIST P8Platform)

    check_dependency_build(${CMAKE_FIND_PACKAGE_NAME} "${${CMAKE_FIND_PACKAGE_NAME}_DEPLIST}")
  endif()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC cec)

  SETUP_BUILD_VARS()

  SETUP_FIND_SPECS()

  # Check for existing libcec. If version >= LIBCEC-VERSION file version, dont build
  find_package(libcec ${CONFIG_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} CONFIG ${SEARCH_QUIET}
                      HINTS ${DEPENDS_PATH}/lib/cmake
                      ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  # cmake config may not be available (eg Debian libcec-dev package)
  # fallback to pkgconfig for non windows platforms
  if(NOT libcec_FOUND)
    find_package(PkgConfig ${SEARCH_QUIET})
    if(PKG_CONFIG_FOUND AND NOT (WIN32 OR WINDOWSSTORE))
      pkg_check_modules(libcec libcec${PC_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} ${SEARCH_QUIET} IMPORTED_TARGET)
    endif()
  endif()

  if((libcec_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND ENABLE_INTERNAL_CEC) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_CEC) OR
     (DEFINED ${CMAKE_FIND_PACKAGE_NAME}_FORCE_BUILD))
    # Build lib
    buildCEC()
  else()
    if(TARGET libcec::cec)
      get_target_property(_CEC_CONFIGURATIONS libcec::cec IMPORTED_CONFIGURATIONS)
      if(_CEC_CONFIGURATIONS)
        foreach(_cec_config IN LISTS _CEC_CONFIGURATIONS)
          # Some non standard config (eg None on Debian)
          # Just set to RELEASE var so select_library_configurations can continue to work its magic
          string(TOUPPER ${_cec_config} _cec_config_UPPER)
          if((NOT ${_cec_config_UPPER} STREQUAL "RELEASE") AND
             (NOT ${_cec_config_UPPER} STREQUAL "DEBUG"))
            get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE libcec::cec IMPORTED_LOCATION_${_cec_config_UPPER})
          else()
            get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_${_cec_config_UPPER} libcec::cec IMPORTED_LOCATION_${_cec_config_UPPER})
          endif()
        endforeach()
      else()
        get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE libcec::cec IMPORTED_LOCATION)
      endif()

      # CEC cmake config doesnt include INTERFACE_INCLUDE_DIRECTORIES
      find_path(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR NAMES libcec/cec.h libCEC/CEC.h
                                                                 HINTS ${DEPENDS_PATH}/include
                                                                 ${${CORE_PLATFORM_LC}_SEARCH_CONFIG})
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${libcec_VERSION})
    elseif(TARGET PkgConfig::libcec)
      # First item is the full path of the library file found
      # pkg_check_modules does not populate a variable of the found library explicitly
      list(GET libcec_LINK_LIBRARIES 0 ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE)

      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR PkgConfig::libcec INTERFACE_INCLUDE_DIRECTORIES)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${libcec_VERSION})
    endif()
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(${${CMAKE_FIND_PACKAGE_NAME}_MODULE})
  unset(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(CEC
                                    REQUIRED_VARS ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR
                                    VERSION_VAR ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION)

  if(CEC_FOUND)
    if(TARGET libcec::cec AND NOT TARGET cec)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS libcec::cec)
      # We need to append in case the cmake config already has definitions
      set_property(TARGET libcec::cec APPEND PROPERTY
                                             INTERFACE_COMPILE_DEFINITIONS HAVE_LIBCEC)
    elseif(TARGET PkgConfig::libcec AND NOT TARGET cec)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::libcec)
      set_property(TARGET PkgConfig::libcec APPEND PROPERTY
                                                   INTERFACE_COMPILE_DEFINITIONS HAVE_LIBCEC)
    else()
      if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB)
        add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} SHARED IMPORTED)
      else()
        add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} STATIC IMPORTED)
      endif()

      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                       INTERFACE_COMPILE_DEFINITIONS HAVE_LIBCEC
                                                                       INTERFACE_INCLUDE_DIRECTORIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR}"
                                                                       IMPORTED_LOCATION "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY}")
      if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB)
        if(WIN32 OR WINDOWS_STORE)
          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_IMPLIB "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_IMPLIB}")
        endif()
      endif()
    endif()

    if(TARGET cec)
      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} cec)
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
      if(NOT TARGET cec)
        buildCEC()
        set_target_properties(cec PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
      add_dependencies(build_internal_depends cec)
    endif()
  endif()
endif()
