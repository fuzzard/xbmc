#.rst:
# FindTagLib
# ----------
# Finds the TagLib library
#
# This will define the following variables::
#
# TAGLIB_FOUND - system has TagLib
# TAGLIB_INCLUDE_DIRS - the TagLib include directory
# TAGLIB_LIBRARIES - the TagLib libraries
#
# and the following imported targets::
#
#   TagLib::TagLib   - The TagLib library

if(ENABLE_INTERNAL_TAGLIB)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC taglib)

  SETUP_BUILD_VARS()

  if(APPLE)
    set(EXTRA_ARGS "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}")
  endif()

  # ToDo: Windows - requires patching

#  if(WIN32 OR WINDOWS_STORE)
#    # find the path to the patch executable
#    find_program(PATCH_EXECUTABLE NAMES patch patch.exe REQUIRED)
#
#    set(patch ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/001-windows-pdb-symbol-gen.patch)
#    PATCH_LF_CHECK(${patch})
#
#    set(PATCH_COMMAND ${PATCH_EXECUTABLE} -p1 -i ${patch})
#  endif()

  # Suppress mismatch warning, see https://cmake.org/cmake/help/latest/module/FindPackageHandleStandardArgs.html
  set(FPHSA_NAME_MISMATCHED 1)
  find_package(Zlib REQUIRED)
  unset(FPHSA_NAME_MISMATCHED)

  set(TAGLIB_VERSION ${${MODULE}_VER})

  set(CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                 -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
                 -DCMAKE_PREFIX_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                 -DBUILD_SHARED_LIBS=OFF
                 -DBUILD_BINDINGS=OFF
                 "${EXTRA_ARGS}")

  BUILD_DEP_TARGET()

else()
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_TAGLIB taglib>=1.9.0 QUIET)
  endif()

  find_path(TAGLIB_INCLUDE_DIR taglib/tag.h
                               PATHS ${PC_TAGLIB_INCLUDEDIR})
  find_library(TAGLIB_LIBRARY_RELEASE NAMES tag
                                      PATHS ${PC_TAGLIB_LIBDIR})
  find_library(TAGLIB_LIBRARY_DEBUG NAMES tagd
                                    PATHS ${PC_TAGLIB_LIBDIR})
  set(TAGLIB_VERSION ${PC_TAGLIB_VERSION})

  include(SelectLibraryConfigurations)
  select_library_configurations(TAGLIB)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(TagLib
                                  REQUIRED_VARS TAGLIB_LIBRARY TAGLIB_INCLUDE_DIR
                                  VERSION_VAR TAGLIB_VERSION)

if(TAGLIB_FOUND)
  set(TAGLIB_LIBRARIES ${TAGLIB_LIBRARY})

  # Workaround broken .pc file
  list(APPEND TAGLIB_LIBRARIES ${PC_TAGLIB_ZLIB_LIBRARIES})

  set(TAGLIB_INCLUDE_DIRS ${TAGLIB_INCLUDE_DIR})
  if(NOT TARGET TagLib::TagLib)
    add_library(TagLib::TagLib UNKNOWN IMPORTED)
    if(TAGLIB_LIBRARY_RELEASE)
      set_target_properties(TagLib::TagLib PROPERTIES
                                           IMPORTED_CONFIGURATIONS RELEASE
                                           IMPORTED_LOCATION "${TAGLIB_LIBRARY_RELEASE}")
    endif()
    if(TAGLIB_LIBRARY_DEBUG)
      set_target_properties(TagLib::TagLib PROPERTIES
                                           IMPORTED_CONFIGURATIONS DEBUG
                                           IMPORTED_LOCATION "${TAGLIB_LIBRARY_DEBUG}")
    endif()
    set_target_properties(TagLib::TagLib PROPERTIES
                                         INTERFACE_INCLUDE_DIRECTORIES "${TAGLIB_INCLUDE_DIR}")
  endif()
endif()

mark_as_advanced(TAGLIB_INCLUDE_DIR TAGLIB_LIBRARY)
