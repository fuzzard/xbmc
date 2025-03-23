#.rst:
# FindLibAACS
# ----------
# Finds the libaacs library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::LibAACS   - The libaacs library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  macro(buildmacroLibAACS)

    set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/01-all-remove_versioning.patch"
                "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/02-all-AACS_HOME-env.patch")

    if(CORE_SYSTEM_NAME MATCHES windows)
      list(APPEND patches "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/03-win-cmake.patch"
                          "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/04-win-UWP.patch"
                          "${CORE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/05-win-fix_gcrypt_build.patch")
    endif()

    generate_patchcommand("${patches}")

    if(CORE_SYSTEM_NAME MATCHES windows)
      find_package(libgpg-error CONFIG REQUIRED ${SEARCH_QUIET})
      find_package(libgcrypt CONFIG REQUIRED ${SEARCH_QUIET})
      find_package(iconv CONFIG REQUIRED ${SEARCH_QUIET})

      # Override build type detection and always build as release
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_TYPE Release)

      set(CMAKE_ARGS -DNATIVEPREFIX=${NATIVEPREFIX})
    else()

      if(CMAKE_HOST_SYSTEM_NAME MATCHES "(Free|Net|Open)BSD")
        find_program(MAKE_EXECUTABLE gmake)
      endif()
      find_program(MAKE_EXECUTABLE make REQUIRED)
      find_program(AUTORECONF autoreconf REQUIRED)

      pkg_check_modules(libgcrypt libgcrypt REQUIRED ${SEARCH_QUIET})
      pkg_check_modules(gpg-error gpg-error REQUIRED ${SEARCH_QUIET})

      set(CONFIGURE_COMMAND ./bootstrap
                    COMMAND ./configure
                            --prefix=${DEPENDS_PATH}
                            --disable-static
                            --exec-prefix=${DEPENDS_PATH})

      set(BUILD_COMMAND ${MAKE_EXECUTABLE})
      set(INSTALL_COMMAND ${MAKE_EXECUTABLE} install)
      set(BUILD_IN_SOURCE 1)
  
      if(CORE_SYSTEM_NAME STREQUAL "osx")
        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LOCATION_POSTFIX "dylib")
      endif()
    endif()

    BUILD_DEP_TARGET()

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})
  endmacro()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC libaacs)

  SETUP_BUILD_VARS()

  # Kodi libaacs-0.9.0-* prebuilt libs have a broken cmake config file
  # We need to detect this, otherwise the call to find_package will run and error out
  if(EXISTS ${DEPENDS_PATH}/lib/cmake/libaacs/libaacs-config.cmake)
    file(READ ${DEPENDS_PATH}/lib/cmake/libaacs/libaacs-config.cmake aacs_config_output)
    string(FIND ${aacs_config_output} "libbdplus.cmake" BROKEN_CONFIG)
  else()
    set(BROKEN_CONFIG -1)
  endif()

  # Only do a package check if the broken config is not found
  if(NOT (${BROKEN_CONFIG} GREATER "-1"))
    find_package(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} ${CONFIG_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} CONFIG ${SEARCH_QUIET}
                                                           HINTS ${DEPENDS_PATH}/lib/cmake
                                                           ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})
  endif()

  # fallback to pkgconfig for non windows platforms
  if(NOT ${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_FOUND)
    find_package(PkgConfig ${SEARCH_QUIET})

    if(PKG_CONFIG_FOUND AND NOT (WIN32 OR WINDOWSSTORE))
      pkg_check_modules(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} ${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}${PC_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} ${SEARCH_QUIET} IMPORTED_TARGET)
    endif()
  endif()

  if(${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME}_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})
    cmake_language(EVAL CODE "
      buildmacro${CMAKE_FIND_PACKAGE_NAME}()
    ")
  else()
    if(TARGET libaacs::libaacs)
      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY libaacs::libaacs IMPORTED_LOCATION_RELEASE)
      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR libaacs::libaacs INTERFACE_INCLUDE_DIRECTORIES)
    elseif(TARGET PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME})
      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} INTERFACE_LINK_LIBRARIES)
      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} INTERFACE_INCLUDE_DIRECTORIES)
    endif()
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LibAACS
                                    REQUIRED_VARS ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR
                                    VERSION_VAR ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION)

  if(LibAACS_FOUND)
    if(TARGET libaacs::libaacs AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS libaacs::libaacs)
    elseif(TARGET PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME} AND NOT TARGET ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::${${CMAKE_FIND_PACKAGE_NAME}_SEARCH_NAME})
    else()
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} INTERFACE IMPORTED)
      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                       INTERFACE_INCLUDE_DIRECTORIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR}"
                                                                       INTERFACE_LINK_LIBRARIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY}")

      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_NAME})
    endif()

    ADD_MULTICONFIG_BUILDMACRO()
  else()
    if(LibAACS_FIND_REQUIRED)
      message(FATAL_ERROR "libaacs libraries were not found.")
    endif()
  endif()
endif()
