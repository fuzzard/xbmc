#.rst:
# FindBluray
# ----------
# Finds the libbluray library
#
# This will define the following variables::
#
# BLURAY_FOUND - system has libbluray
# BLURAY_INCLUDE_DIRS - the libbluray include directory
# BLURAY_LIBRARIES - the libbluray libraries
# BLURAY_DEFINITIONS - the libbluray compile definitions
#
# and the following imported targets::
#
#   Bluray::Bluray   - The libbluray library

if(ENABLE_INTERNAL_BLURAY)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  # Suppress mismatch warning, see https://cmake.org/cmake/help/latest/module/FindPackageHandleStandardArgs.html
  set(FPHSA_NAME_MISMATCHED 1)
  # Build tools
  find_program(AUTORECONF autoreconf REQUIRED)
  find_program(PATCH_EXECUTABLE NAMES patch patch.exe REQUIRED)

  # Dependencies
  find_package(fontconfig REQUIRED)
  find_package(freetype REQUIRED)
  find_package(libxml2 REQUIRED)
  find_package(udfread REQUIRED)

  unset(FPHSA_NAME_MISMATCHED)

  set(MODULE_LC libbluray)

  SETUP_BUILD_VARS()

  set(PC_BLURAY_STATIC_LIBRARIES ${FONTCONFIG_LIBRARIES} ${FREETYPE_LIBRARIES} ${LIBXML2_LIBRARIES} ${UDFREAD_LIBRARIES})

  set(BLURAY_INCLUDE_DIR ${${MODULE}_INCLUDE_DIR})
  set(BLURAY_LIBRARY ${${MODULE}_LIBRARY})
  set(BLURAY_VERSION ${${MODULE}_VER})

  if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
    set(PATCH_COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/libbluray/001-darwinembed_DiskArbitration-revert.patch)
    if(CORE_PLATFORM_NAME_LC STREQUAL tvos)
      list(APPEND PATCH_COMMAND COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/libbluray/tvos.patch)
    endif()
  endif()

  set(CONFIGURE_COMMAND ${DEPBUILDENV} ${AUTORECONF} -vif
                COMMAND ${DEPBUILDENV} ./configure --prefix=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                                                   --exec-prefix=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                                                   --disable-examples
                                                   --disable-doxygen-doc
                                                   --disable-bdjava-jar
                                                   --disable-shared)
  set(BUILD_COMMAND make)
  set(BUILD_IN_SOURCE 1)
  set(INSTALL_COMMAND make install)

  BUILD_DEP_TARGET()
  if(ENABLE_INTERNAL_UDFREAD)
    add_dependencies(${MODULE_LC} udfread-build)
  endif()
  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP libbluray)
else()
  set(Bluray_FIND_VERSION 0.9.3)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_BLURAY libbluray>=${Bluray_FIND_VERSION} QUIET)
    set(BLURAY_VERSION ${PC_BLURAY_VERSION})
  endif()

  find_path(BLURAY_INCLUDE_DIR libbluray/bluray.h
                               PATHS ${PC_BLURAY_INCLUDEDIR})

  if(NOT BLURAY_VERSION AND EXISTS ${BLURAY_INCLUDE_DIR}/libbluray/bluray-version.h)
    file(STRINGS ${BLURAY_INCLUDE_DIR}/libbluray/bluray-version.h _bluray_version_str
         REGEX "#define[ \t]BLURAY_VERSION_STRING[ \t][\"]?[0-9.]+[\"]?")
    string(REGEX REPLACE "^.*BLURAY_VERSION_STRING[ \t][\"]?([0-9.]+).*$" "\\1" BLURAY_VERSION ${_bluray_version_str})
    unset(_bluray_version_str)
  endif()

  find_library(BLURAY_LIBRARY NAMES bluray libbluray
                              PATHS ${PC_BLURAY_LIBDIR})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Bluray
                                  REQUIRED_VARS BLURAY_LIBRARY BLURAY_INCLUDE_DIR BLURAY_VERSION
                                  VERSION_VAR BLURAY_VERSION)

if(BLURAY_FOUND)
  set(BLURAY_LIBRARIES ${BLURAY_LIBRARY})
  set(BLURAY_INCLUDE_DIRS ${BLURAY_INCLUDE_DIR})
  set(BLURAY_DEFINITIONS -DHAVE_LIBBLURAY=1)

  # todo: improve syntax
  if (NOT CORE_PLATFORM_NAME_LC STREQUAL windowsstore)
    list(APPEND BLURAY_DEFINITIONS -DHAVE_LIBBLURAY_BDJ=1)
  endif()

  if(${BLURAY_LIBRARY} MATCHES ".+\.a$" AND PC_BLURAY_STATIC_LIBRARIES)
    list(APPEND BLURAY_LIBRARIES ${PC_BLURAY_STATIC_LIBRARIES})
  endif()

  if(NOT TARGET Bluray::Bluray)
    add_library(Bluray::Bluray UNKNOWN IMPORTED)
    if(BLURAY_LIBRARY)
      set_target_properties(Bluray::Bluray PROPERTIES
                                           IMPORTED_LOCATION "${BLURAY_LIBRARY}")
    endif()
    set_target_properties(Bluray::Bluray PROPERTIES
                                         INTERFACE_INCLUDE_DIRECTORIES "${BLURAY_INCLUDE_DIR}"
                                         INTERFACE_COMPILE_DEFINITIONS HAVE_LIBBLURAY=1)
  endif()
endif()

mark_as_advanced(BLURAY_INCLUDE_DIR BLURAY_LIBRARY)
