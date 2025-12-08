#.rst:
# FindFriBidi
# -----------
# Finds the GNU FriBidi library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::FriBidi   - The FriBidi library
#   LIBRARY::FriBidi   - An ALIAS of the FriBidi library
#   FriBidi::FriBidi   - An ALIAS of the FriBidi library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})
  include(cmake/scripts/common/ModuleHelpers.cmake)

  macro(buildmacroFriBidi)

    find_package(Meson REQUIRED)
    find_package(Ninja REQUIRED)

    if(WIN32 OR WINDOWS_STORE)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_libType shared)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB TRUE)

      set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/01-win-remove_lib_version.patch")

      generate_patchcommand("${patches}")
      unset(patches)

      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_COMPILE_DEFINITIONS FRIBIDI_BUILD)

      if(WINDOWS_STORE)
        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_EXE_LINKER_FLAGS "/APPCONTAINER windowsapp.lib")
      endif()

      # set host binary names for use with envwrapper script
      set(CC_FOR_BUILD "cl.exe")
      set(LD_FOR_BUILD "link.exe")
      set(CXX_FOR_BUILD "cl.exe")
      set(AR_FOR_BUILD "lib.exe")

      create_module_dev_env()
    else()
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_libType static)
    endif()

    # generate meson cross file for build target
    generate_mesoncrossfile()

    # generate native tools meson cross file for host
    generate_mesonnativefile()

    if(EXISTS ${DEPENDS_PATH}/share/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}-cross-file.meson)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_CROSS_FILE --cross-file=${DEPENDS_PATH}/share/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}-cross-file.meson)
    elseif(EXISTS ${DEPENDS_PATH}/share/cross-file.meson)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_CROSS_FILE --cross-file=${DEPENDS_PATH}/share/cross-file.meson)
    endif()

    if(EXISTS ${NATIVEPREFIX}/share/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}-native-file.meson)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_NATIVE_FILE --native-file=${NATIVEPREFIX}/share/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}-native-file.meson)
    elseif(EXISTS ${NATIVEPREFIX}/share/native-file.meson)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_NATIVE_FILE --native-file=${NATIVEPREFIX}/share/native-file.meson)
    endif()

    set(CONFIGURE_COMMAND ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_dev_env}
                          ${CMAKE_COMMAND} -E env --modify NINJA=set:${NINJA_EXECUTABLE}
                          ${MESON_EXECUTABLE} setup ./build
                          --buildtype=release
                          --default-library=${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_libType}
                          --prefix=${DEPENDS_PATH}
                          --libdir=lib
                          -Ddocs=false
                          -Dtests=false
                          -Dbin=false
                          ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_NATIVE_FILE}
                          ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_CROSS_FILE})

    set(BUILD_COMMAND ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_dev_env}
                      ${NINJA_EXECUTABLE} -C ./build)
    set(INSTALL_COMMAND ${NINJA_EXECUTABLE} -C ./build install)
    set(BUILD_IN_SOURCE 1)

    # create include path or libs that depend on Fribidi may complain about non existent include folder
    file(MAKE_DIRECTORY "${DEPENDS_PATH}/include/fribidi")
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR "${DEPENDS_PATH}/include/fribidi")

    BUILD_DEP_TARGET()
  endmacro()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC fribidi)

  SETUP_BUILD_VARS()

  SETUP_FIND_SPECS()

  SEARCH_EXISTING_PACKAGES()

  if(("${${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_VERSION}" VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND ENABLE_INTERNAL_FRIBIDI) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_FRIBIDI))
    message(STATUS "Building ${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}: \(version \"${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER}\"\)")
    cmake_language(EVAL CODE "
      buildmacro${CMAKE_FIND_PACKAGE_NAME}()
    ")

    # Meson uses pkgconfig, therefore we no longer need the windows cmake config.
    # remove the cmake config, as otherwise our search order will constantly find the old
    # cmake config lib rather than the new pkgconfig
    if(TARGET fribidi::fribidi)
      if(EXISTS "${DEPENDS_PATH}/lib/cmake/fribidi")
        file(REMOVE_RECURSE "${DEPENDS_PATH}/lib/cmake/fribidi")
      endif()
    endif()
  endif()

  if(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_FOUND)
    if(TARGET PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME})
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME})
    elseif(TARGET fribidi::fribidi AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS fribidi::fribidi)
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS fribidi::fribidi)
    else()
      SETUP_BUILD_TARGET()

      # Add ALIAS TARGET as Fribidi can be a dependency of other libs
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})

      # We are building as a requirement, so set LIB_BUILD property to allow calling
      # modules to know we will be building, and they will want to rebuild as well.
      # Property must be set on actual TARGET and not the ALIAS
      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES LIB_BUILD ON)
    endif()

    if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_COMPILE_DEFINITIONS)
      ADD_TARGET_COMPILE_DEFINITION()
    endif()

    ADD_MULTICONFIG_BUILDMACRO()

    # Common TARGET name other libs use
    if(NOT TARGET FriBidi::FriBidi)
      get_target_property(_ALIASTARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIASED_TARGET)

      if(_ALIASTARGET)
        set(LIB_TARGET ${_ALIASTARGET})
      else()
        set(LIB_TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})
      endif()

      add_library(FriBidi::FriBidi ALIAS ${LIB_TARGET})
    endif()
  else()
    if(FriBidi_FIND_REQUIRED)
      message(FATAL_ERROR "FriBidi library was not found.")
    endif()
  endif()
endif()
