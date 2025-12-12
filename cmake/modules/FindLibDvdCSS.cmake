#.rst:
# FindLibDvdCSS
# ----------
# Finds the libdvdcss library
#
# This will define the following target:
#
#   LibDvdCSS::LibDvdCSS   - The LibDvdCSS library

if(NOT TARGET LibDvdCSS::LibDvdCSS)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  macro(buildmacroLibDvdCSS)

    find_package(Meson REQUIRED)
    find_package(Ninja REQUIRED)

    set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/01-all-libcread.patch")

    if(WIN32 OR WINDOWS_STORE)
      if(WINDOWS_STORE)
        list(APPEND patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/03-win-uwp.patch")

        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_CXX_FLAGS "/DWINAPI_FAMILY=WINAPI_FAMILY_APP")
        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_EXE_LINKER_FLAGS "/APPCONTAINER windowsapp.lib /defaultlib:vccorlib.lib /defaultlib:msvcrt.lib")
      endif()

      create_module_dev_env()
    elseif(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
      list(APPEND patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/02-darwinembed-iosbuild.patch")
    endif()

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_libType static)

    generate_patchcommand("${patches}")
    unset(patches)

    # generate meson cross file for build target
    generate_mesoncrossfile()

    if(EXISTS ${DEPENDS_PATH}/share/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}-cross-file.meson)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_CROSS_FILE --cross-file=${DEPENDS_PATH}/share/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}-cross-file.meson)
    elseif(EXISTS ${DEPENDS_PATH}/share/cross-file.meson)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_CROSS_FILE --cross-file=${DEPENDS_PATH}/share/cross-file.meson)
    endif()

    set(CONFIGURE_COMMAND ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_dev_env}
                          ${CMAKE_COMMAND} -E env --modify NINJA=set:${NINJA_EXECUTABLE}
                          ${MESON_EXECUTABLE} setup ./build
                          --buildtype=release
                          --default-library=${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_libType}
                          --prefix=${DEPENDS_PATH}
                          --libdir=lib
                          -Denable_docs=false
                          -Denable_examples=false
                          ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_CROSS_FILE})

    set(BUILD_COMMAND ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_dev_env}
                      ${NINJA_EXECUTABLE} -C ./build)
    set(INSTALL_COMMAND ${NINJA_EXECUTABLE} -C ./build install)
    set(BUILD_IN_SOURCE 1)

    BUILD_DEP_TARGET()

  endmacro()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC libdvdcss)

  SETUP_BUILD_VARS()

  SETUP_FIND_SPECS()

  SEARCH_EXISTING_PACKAGES()

  if(("${${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_VERSION}" VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND ENABLE_DVDCSS) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_DVDCSS))

    # For now, just always build. This is the same outcome as previous.
    message(STATUS "Building ${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}: \(version \"${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER}\"\)")

    cmake_language(EVAL CODE "
      buildmacro${CMAKE_FIND_PACKAGE_NAME}()
    ")
  endif()

  if(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_FOUND)
    SETUP_BUILD_TARGET()

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_COMPILE_DEFINITIONS HAVE_DVDCSS_DVDCSS_H)
    ADD_TARGET_COMPILE_DEFINITION()

    add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
  else()
    if(LibDvdCSS_FIND_REQUIRED)
      message(FATAL_ERROR "Libdvdcss not found. Possibly remove -DENABLE_DVDCSS=ON.")
    endif()
  endif()
endif()
