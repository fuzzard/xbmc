#.rst:
# FindTinyXML
# -----------
# Finds the TinyXML library
#
# This will define the following variables::
#
# TINYXML_FOUND - system has TinyXML
# TINYXML_INCLUDE_DIRS - the TinyXML include directory
# TINYXML_LIBRARIES - the TinyXML libraries
# TINYXML_DEFINITIONS - the TinyXML definitions
#
# and the following imported targets::
#
#   TinyXML::TinyXML   - The TinyXML library

include(cmake/scripts/common/ModuleHelpers.cmake)

if(ENABLE_INTERNAL_TINYXML)
  set(MODULE_LC tinyxml)

  SETUP_BUILD_VARS()

  if(CORE_SYSTEM_NAME MATCHES windows)
    find_package(tinyXML CONFIG QUIET)
    set(TINYXML_VERSION ${tinyXML_VERSION})
  else()
    find_package(PkgConfig REQUIRED)

    if(PKG_CONFIG_FOUND)
      pkg_check_modules(PC_TINYXML tinyxml QUIET)
      set(TINYXML_VERSION ${PC_TINYXML_VERSION})
    endif()
  endif()

  if(NOT (PC_TINYXML_FOUND OR tinyXML_FOUND) AND TINYXML_VERSION VERSION_LESS "2.6.2")
    # build
    set(TINYXML_VERSION "2.6.2")

    if(CORE_SYSTEM_NAME MATCHES windows)
      set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/001-win-cmake.patch")
      generate_patchcommand("${patches}")

      # No arguments required.
      set(CMAKE_ARGS -DDUMMY_DEFINE=ON)
    else()
      find_program(AUTORECONF autoreconf REQUIRED)
      find_program(MAKE_EXECUTABLE make REQUIRED)

      set(CONFIGURE_COMMAND ${AUTORECONF} -vif
                    COMMAND ./configure
                            --disable-shared
                            --prefix=${DEPENDS_PATH})
      set(BUILD_COMMAND ${MAKE_EXECUTABLE} -C src)
      set(INSTALL_COMMAND ${MAKE_EXECUTABLE} -C src install)
      set(BUILD_IN_SOURCE 1)
    endif()

    BUILD_DEP_TARGET()
  else()
    # pkg-config found (*nix)
    # cmake-config found (windows)
    find_path(TINYXML_INCLUDE_DIR tinyxml.h
                                  PATH_SUFFIXES tinyxml
                                  HINTS ${PC_TINYXML_INCLUDEDIR}
                                        ${DEPENDS_PATH}/include)
    find_library(TINYXML_LIBRARY_RELEASE NAMES tinyxml tinyxmlSTL
                                         PATH_SUFFIXES tinyxml
                                         HINTS ${PC_TINYXML_LIBDIR}
                                               ${DEPENDS_PATH}/lib)
    find_library(TINYXML_LIBRARY_DEBUG NAMES tinyxmld tinyxmlSTLd
                                       PATH_SUFFIXES tinyxml
                                       HINTS ${PC_TINYXML_LIBDIR}
                                             ${DEPENDS_PATH}/lib)
    set(TINYXML_VERSION ${PC_TINYXML_VERSION})
  endif()
else()

  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_TINYXML tinyxml QUIET)
  endif()

  find_path(TINYXML_INCLUDE_DIR tinyxml.h
                                PATH_SUFFIXES tinyxml
                                PATHS ${PC_TINYXML_INCLUDEDIR})
  find_library(TINYXML_LIBRARY_RELEASE NAMES tinyxml tinyxmlSTL
                                       PATH_SUFFIXES tinyxml
                                       PATHS ${PC_TINYXML_LIBDIR})
  find_library(TINYXML_LIBRARY_DEBUG NAMES tinyxmld tinyxmlSTLd
                                     PATH_SUFFIXES tinyxml
                                     PATHS ${PC_TINYXML_LIBDIR})
  set(TINYXML_VERSION ${PC_TINYXML_VERSION})

endif()

include(SelectLibraryConfigurations)
select_library_configurations(TINYXML)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(TinyXML
                                  REQUIRED_VARS TINYXML_LIBRARY TINYXML_INCLUDE_DIR
                                  VERSION_VAR TINYXML_VERSION)

if(TINYXML_FOUND)
  set(TINYXML_LIBRARIES ${TINYXML_LIBRARY})
  set(TINYXML_INCLUDE_DIRS ${TINYXML_INCLUDE_DIR})
  if(WIN32)
    set(TINYXML_DEFINITIONS -DTIXML_USE_STL=1)
  endif()

  if(NOT TARGET TinyXML::TinyXML)
    add_library(TinyXML::TinyXML UNKNOWN IMPORTED)
    if(TINYXML_LIBRARY_RELEASE)
      set_target_properties(TinyXML::TinyXML PROPERTIES
                                             IMPORTED_CONFIGURATIONS RELEASE
                                             IMPORTED_LOCATION "${TINYXML_LIBRARY_RELEASE}")
    endif()
    if(TINYXML_LIBRARY_DEBUG)
      set_target_properties(TinyXML::TinyXML PROPERTIES
                                             IMPORTED_CONFIGURATIONS DEBUG
                                             IMPORTED_LOCATION "${TINYXML_LIBRARY_DEBUG}")
    endif()
    set_target_properties(TinyXML::TinyXML PROPERTIES
                                           INTERFACE_INCLUDE_DIRECTORIES "${TINYXML_INCLUDE_DIR}")
    if(WIN32)
      set_target_properties(TinyXML::TinyXML PROPERTIES
                                             INTERFACE_COMPILE_DEFINITIONS TIXML_USE_STL=1)
    endif()
  endif()
  if(TARGET tinyxml)
    add_dependencies(TinyXML::TinyXML tinyxml)
  endif()
  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP TinyXML::TinyXML)
else()
  if(TinyXML_FIND_REQUIRED)
    message(FATAL_ERROR "TinyXML not found. Possibly try -DENABLE_INTERNAL_TINYXML=ON")
  endif()
endif()

mark_as_advanced(TINYXML_INCLUDE_DIR TINYXML_LIBRARY)
