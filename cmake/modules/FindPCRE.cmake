#.rst:
# FindPCRE
# --------
# Finds the PCRECPP library
#
# This will define the following variables::
#
# PCRE_FOUND - system has libpcrecpp
# PCRE_INCLUDE_DIRS - the libpcrecpp include directory
# PCRE_LIBRARIES - the libpcrecpp libraries
# PCRE_DEFINITIONS - the libpcrecpp definitions
#
# and the following imported targets::
#
#   PCRE::PCRECPP - The PCRECPP library
#   PCRE::PCRE    - The PCRE library

if(ENABLE_INTERNAL_PCRE)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC pcre)

  SETUP_BUILD_VARS()

  if(APPLE)
    set(EXTRA_ARGS "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}")
  endif()

  # ToDo: Windows

  set(PCRE_VERSION ${${MODULE}_VER})
  set(PCRECPP_LIBRARY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/libpcrecpp.a)

  if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
    set(PATCH_COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/pcre/ios-clear_cache.patch)
    if(CORE_PLATFORM_NAME STREQUAL tvos)
      list(APPEND PATCH_COMMAND COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/pcre/tvos-bitcode-fix.patch)
    endif()
  elseif(CORE_SYSTEM_NAME STREQUAL android)
    set(PATCH_COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/pcre/jit_aarch64.patch)
  endif()

  set(CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                 -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
                 -DCMAKE_PREFIX_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                 -DPCRE_NEWLINE=ANYCRLF
                 -DPCRE_NO_RECURSE=ON
                 -DPCRE_SUPPORT_JIT=ON
                 -DPCRE_SUPPORT_PCREGREP_JIT=OFF
                 -DPCRE_SUPPORT_UTF=ON
                 -DPCRE_SUPPORT_UNICODE_PROPERTIES=ON
                 -DPCRE_BUILD_PCREGREP=OFF
                 -DPCRE_BUILD_TESTS=OFF
                 "${EXTRA_ARGS}")

  BUILD_DEP_TARGET()

else()
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_PCRE libpcrecpp QUIET)
  endif()

  find_path(PCRE_INCLUDE_DIR pcrecpp.h
                             PATHS ${PC_PCRE_INCLUDEDIR})
  find_library(PCRECPP_LIBRARY_RELEASE NAMES pcrecpp
                                       PATHS ${PC_PCRE_LIBDIR})
  find_library(PCRE_LIBRARY_RELEASE NAMES pcre
                                    PATHS ${PC_PCRE_LIBDIR})
  find_library(PCRECPP_LIBRARY_DEBUG NAMES pcrecppd
                                     PATHS ${PC_PCRE_LIBDIR})
  find_library(PCRE_LIBRARY_DEBUG NAMES pcred
                                     PATHS ${PC_PCRE_LIBDIR})
  set(PCRE_VERSION ${PC_PCRE_VERSION})

  include(SelectLibraryConfigurations)
  select_library_configurations(PCRECPP)
  select_library_configurations(PCRE)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PCRE
                                  REQUIRED_VARS PCRECPP_LIBRARY PCRE_LIBRARY PCRE_INCLUDE_DIR
                                  VERSION_VAR PCRE_VERSION)

if(PCRE_FOUND)
  set(PCRE_LIBRARIES ${PCRECPP_LIBRARY} ${PCRE_LIBRARY})
  set(PCRE_INCLUDE_DIRS ${PCRE_INCLUDE_DIR})
  if(WIN32)
    set(PCRE_DEFINITIONS -DPCRE_STATIC=1)
  endif()

  if(NOT TARGET PCRE::PCRE)
    add_library(PCRE::PCRE UNKNOWN IMPORTED)
    if(PCRE_LIBRARY_RELEASE)
      set_target_properties(PCRE::PCRE PROPERTIES
                                       IMPORTED_CONFIGURATIONS RELEASE
                                       IMPORTED_LOCATION "${PCRE_LIBRARY_RELEASE}")
    endif()
    if(PCRE_LIBRARY_DEBUG)
      set_target_properties(PCRE::PCRE PROPERTIES
                                       IMPORTED_CONFIGURATIONS DEBUG
                                       IMPORTED_LOCATION "${PCRE_LIBRARY_DEBUG}")
    endif()
    set_target_properties(PCRE::PCRE PROPERTIES
                                     INTERFACE_INCLUDE_DIRECTORIES "${PCRE_INCLUDE_DIR}")
    if(WIN32)
      set_target_properties(PCRE::PCRE PROPERTIES
                                       INTERFACE_COMPILE_DEFINITIONS PCRE_STATIC=1)
    endif()

  endif()
  if(NOT TARGET PCRE::PCRECPP)
    add_library(PCRE::PCRECPP UNKNOWN IMPORTED)
    if(PCRE_LIBRARY_RELEASE)
      set_target_properties(PCRE::PCRECPP PROPERTIES
                                          IMPORTED_CONFIGURATIONS RELEASE
                                          IMPORTED_LOCATION "${PCRECPP_LIBRARY_RELEASE}")
    endif()
    if(PCRE_LIBRARY_DEBUG)
      set_target_properties(PCRE::PCRECPP PROPERTIES
                                          IMPORTED_CONFIGURATIONS DEBUG
                                          IMPORTED_LOCATION "${PCRECPP_LIBRARY_DEBUG}")
    endif()
    set_target_properties(PCRE::PCRECPP PROPERTIES
                                        INTERFACE_LINK_LIBRARIES PCRE::PCRE)
  endif()
endif()

mark_as_advanced(PCRE_INCLUDE_DIR PCRECPP_LIBRARY PCRE_LIBRARY)
