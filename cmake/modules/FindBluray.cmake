#.rst:
# FindBluray
# ----------
# Finds the libbluray library
#
# This will define the following target:
#
#   ${APP_NAME_LC}::Bluray   - The libbluray library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  include(cmake/scripts/common/ModuleHelpers.cmake)

  macro(buildlibbluray)

    find_package(FreeType REQUIRED ${SEARCH_QUIET})
    find_package(Iconv REQUIRED ${SEARCH_QUIET})
    find_package(LibXml2 REQUIRED ${SEARCH_QUIET})
    find_package(Udfread REQUIRED ${SEARCH_QUIET})

    # Posix platforms use fontconfig
    if(NOT (WIN32 OR WINDOWS_STORE))
      find_package(Fontconfig REQUIRED ${SEARCH_QUIET})
    endif()

    set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/001-darwinembed_DiskArbitration-revert.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/002-darwin-dlopen_searchpath.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/003-all-java21-buildsupport.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/004-all-build_without_bdj.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/005-all-symbolvisibility.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/006-win-cmake.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/007-win-uwp.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/008-win-build_fixes.patch")

    if(WIN32 OR (CORE_SYSTEM_NAME STREQUAL "osx"))
      find_package(Java COMPONENTS Development ${SEARCH_QUIET})

      if(Java_Development_FOUND)
        if(Java_VERSION_MAJOR VERSION_GREATER_EQUAL "9")
          list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/009-java-9_bdframepeer.patch")
        else()
          list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/009-java-1.8_bdframepeer.patch")
        endif()

        find_program(ANT_EXECUTABLE NAMES ant
                                    HINTS ${DEPENDS_PATH}/share/ant/bin
                                    PATHS $ENV{ANT_HOME}/bin)

        if(ANT_EXECUTABLE)
          get_filename_component(ANT_HOME "${ANT_EXECUTABLE}" PATH)
          get_filename_component(ANT_HOME "${ANT_HOME}/.." ABSOLUTE)
          set(ENABLE_BDJ_BUILD TRUE)
        endif()
      endif()
    endif()

    if(NOT ENABLE_BDJ_BUILD)
      set(DISABLE_BDJ_BUILD --disable-bdjava-jar)
    endif()

    generate_patchcommand("${patches}")

    if(WIN32 OR WINDOWS_STORE)

    endif()

    if(WIN32 OR WINDOWS_STORE)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_DEBUG_POSTFIX d)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB TRUE)

      set(CMAKE_ARGS -DDUMMY_ARGS=ON
                     -DBLURAY_API_EXPORT=ON)

      if(ENABLE_BDJ_BUILD)
        list(APPEND CMAKE_ARGS -DANT_HOME=${ANT_HOME})
      endif()
    else()
      find_program(AUTORECONF autoreconf REQUIRED)
      if (CMAKE_HOST_SYSTEM_NAME MATCHES "(Free|Net|Open)BSD")
        find_program(MAKE_EXECUTABLE gmake)
      endif()
      find_program(MAKE_EXECUTABLE make REQUIRED)

      set(CONFIGURE_COMMAND ${AUTORECONF} -vif
                    COMMAND ${CMAKE_COMMAND} -E env PATH=${ANT_HOME}/bin:$ENV{PATH}
                            ANT_HOME=${ANT_HOME}
                            ./configure
                            --prefix=${DEPENDS_PATH}
                            --exec-prefix=${DEPENDS_PATH}
                            --disable-shared
                            --disable-examples
                            --disable-doxygen-doc
                            ${DISABLE_BDJ_BUILD})

      set(BUILD_COMMAND ${CMAKE_COMMAND} -E env PATH=${ANT_HOME}/bin:$ENV{PATH}
                        ${MAKE_EXECUTABLE})
      set(INSTALL_COMMAND ${CMAKE_COMMAND} -E env PATH=${ANT_HOME}/bin:$ENV{PATH}
                          ${MAKE_EXECUTABLE} install)
      set(BUILD_IN_SOURCE 1)
    endif()

    BUILD_DEP_TARGET()

    # Link libraries for target interface
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LINK_LIBRARIES ${APP_NAME_LC}::FreeType ${APP_NAME_LC}::Iconv LibXml2::LibXml2 LIBRARY::Udfread)

    # Add dependencies to build target
    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} ${APP_NAME_LC}::FreeType)
    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} ${APP_NAME_LC}::Iconv)
    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} LibXml2::LibXml2)
    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} LIBRARY::Udfread)

    if(CORE_SYSTEM_NAME STREQUAL "osx")
      list(APPEND ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LINK_LIBRARIES "-framework CoreFoundation"
                                                                      "-framework DiskArbitration")
    endif()

    if(NOT (WIN32 OR WINDOWS_STORE))
      list(APPEND ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LINK_LIBRARIES Fontconfig::Fontconfig)
      add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} Fontconfig::Fontconfig)
    endif()

    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})
  endmacro()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC libbluray)

  SETUP_BUILD_VARS()

  SETUP_FIND_SPECS()

  # Check for existing libcec. If version >= LIBBLURAY-VERSION file version, dont build
  find_package(libbluray ${CONFIG_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} CONFIG ${SEARCH_QUIET}
                         HINTS ${DEPENDS_PATH}/lib/cmake
                         ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  # cmake config may not be available (eg Debian libbluray-dev package)
  # fallback to pkgconfig for non windows platforms
  if(NOT libbluray_FOUND)
    find_package(PkgConfig ${SEARCH_QUIET})
    if(PKG_CONFIG_FOUND AND NOT (WIN32 OR WINDOWSSTORE))
      pkg_check_modules(libbluray libbluray${PC_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} ${SEARCH_QUIET} IMPORTED_TARGET)
    endif()
  endif()

  if((libbluray_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND ENABLE_INTERNAL_BLURAY) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_BLURAY) OR
     (DEFINED ${CMAKE_FIND_PACKAGE_NAME}_FORCE_BUILD))
    # build internal module
    buildlibbluray()
  else()
    if(TARGET libbluray::libbluray)
      get_target_property(_LIBLURAY_CONFIGURATIONS libbluray::libbluray IMPORTED_CONFIGURATIONS)
      if(_LIBLURAY_CONFIGURATIONS)
        foreach(_libbluray_config IN LISTS _LIBLURAY_CONFIGURATIONS)
          # Some non standard config (eg None on Debian)
          # Just set to RELEASE var so select_library_configurations can continue to work its magic
          string(TOUPPER ${_libbluray_config} _libbluray_config_UPPER)
          if((NOT ${_libbluray_config_UPPER} STREQUAL "RELEASE") AND
            (NOT ${_libbluray_config_UPPER} STREQUAL "DEBUG"))
            get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE libbluray::libbluray IMPORTED_LOCATION_${_libbluray_config_UPPER})
          else()
            get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_${_libbluray_config_UPPER} libbluray::libbluray IMPORTED_LOCATION_${_libbluray_config_UPPER})
          endif()
        endforeach()
      else()
        get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE libbluray::libbluray IMPORTED_LOCATION)
      endif()

      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR libbluray::libbluray INTERFACE_INCLUDE_DIRECTORIES)
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${libbluray_VERSION})
    elseif(TARGET PkgConfig::libbluray)
      # First item is the full path of the library file found
      # pkg_check_modules does not populate a variable of the found library explicitly
      list(GET libbluray_LINK_LIBRARIES 0 ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE)
      get_target_property(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR PkgConfig::libbluray INTERFACE_INCLUDE_DIRECTORIES)

      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION ${libbluray_VERSION})
    endif()
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(${${CMAKE_FIND_PACKAGE_NAME}_MODULE})
  unset(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Bluray
                                    REQUIRED_VARS ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR
                                    VERSION_VAR ${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VERSION)

  if(Bluray_FOUND)
    if(TARGET libbluray::libbluray AND NOT TARGET libbluray)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS libbluray::libbluray)
      # We need to append in case the cmake config already has definitions
      set_property(TARGET libbluray::libbluray APPEND PROPERTY
                                                      INTERFACE_COMPILE_DEFINITIONS HAVE_LIBBLURAY)
    elseif(TARGET PkgConfig::libbluray AND NOT TARGET libbluray)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::libbluray)
      set_property(TARGET PkgConfig::libbluray APPEND PROPERTY
                                                      INTERFACE_COMPILE_DEFINITIONS HAVE_LIBBLURAY)
    else()
      if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB)
        add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} SHARED IMPORTED)
      else()
        add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} STATIC IMPORTED)
      endif()

      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                       INTERFACE_COMPILE_DEFINITIONS HAVE_LIBBLURAY
                                                                       INTERFACE_INCLUDE_DIRECTORIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INCLUDE_DIR}"
                                                                       INTERFACE_LINK_LIBRARIES "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LINK_LIBRARIES}")

      if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE)
        set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                         IMPORTED_CONFIGURATIONS RELEASE
                                                                         IMPORTED_LOCATION_RELEASE "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_RELEASE}")
        if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB AND (WIN32 OR WINDOWS_STORE))
          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_IMPLIB_RELEASE "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_IMPLIB_RELEASE}")
        endif()
      endif()

      if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_DEBUG)
        set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                         IMPORTED_LOCATION_DEBUG "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_LIBRARY_DEBUG}")
        set_property(TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} APPEND PROPERTY
                                                                              IMPORTED_CONFIGURATIONS DEBUG)

        if(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_SHARED_LIB AND (WIN32 OR WINDOWS_STORE))
          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_IMPLIB_DEBUG "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_IMPLIB_DEBUG}")
        endif()
      endif()
    endif()

    # This is incorrectly applied to all platforms. Requires its own handling in the future
    if(NOT (CORE_PLATFORM_NAME_LC STREQUAL windowsstore) AND
       NOT (OS STREQUAL darwin_embedded))
      get_property(aliased_target TARGET "${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME}" PROPERTY ALIASED_TARGET)
      set_property(TARGET ${aliased_target} APPEND PROPERTY
                                                   INTERFACE_COMPILE_DEFINITIONS "HAVE_LIBBLURAY_BDJ")
    endif()

    if(TARGET libbluray)
      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} libbluray)
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
      if(NOT TARGET libbluray)
        buildlibbluray()
        set_target_properties(libbluray PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
      add_dependencies(build_internal_depends libbluray)
    endif()
  else()
    if(Bluray_FIND_REQUIRED)
      message(FATAL_ERROR "Libbluray libraries were not found.")
    endif()
  endif()
endif()
