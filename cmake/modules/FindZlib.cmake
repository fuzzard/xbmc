#.rst:
# FindZlib
# ----------
# Finds the Zlib library
#
# This will define the following variables::
#
# ZLIB_FOUND - system has Zlib
# ZLIB_INCLUDE_DIRS - the Zlib include directory
# ZLIB_LIBRARIES - the Zlib libraries
#
# and the following imported targets::
#
#   Zlib::Zlib   - The Zlib library target

include(cmake/scripts/common/ModuleHelpers.cmake)

if(ENABLE_INTERNAL_ZLIB)

  set(MODULE_LC zlib)

  SETUP_BUILD_VARS()

  set(ZLIB_VERSION ${${MODULE}_VER})
 
  set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/01-all-disable_tests.patch"
              "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/02-all-cmake-version.patch")

  generate_patchcommand("${patches}")

  set(ZLIB_DEBUG_POSTFIX "d")

  set(CMAKE_ARGS -DINSTALL_PKGCONFIG_DIR=$(DEP_LOCATION)/lib/pkgconfig)

  BUILD_DEP_TARGET()

else()
  find_package(ZLIB CONFIG QUIET)

  set(ZLIB_INCLUDE_DIR ${ZLIB_INCLUDE_DIRS})
  set(ZLIB_VERSION ${ZLIB_VERSION_STRING})

endif()

include(SelectLibraryConfigurations)
select_library_configurations(ZLIB)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Zlib
                                  REQUIRED_VARS ZLIB_LIBRARY ZLIB_INCLUDE_DIR
                                  VERSION_VAR ZLIB_VERSION)

if(ZLIB_FOUND)
  set(ZLIB_INCLUDE_DIRS ${ZLIB_INCLUDE_DIR})
  set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})

  # Workaround broken .pc file
  list(APPEND TAGLIB_LIBRARIES ${PC_TAGLIB_ZLIB_LIBRARIES})

  if(NOT TARGET Zlib::Zlib)
    add_library(Zlib::Zlib UNKNOWN IMPORTED)
    if(ZLIB_LIBRARY_RELEASE)
      set_target_properties(Zlib::Zlib PROPERTIES
                                       IMPORTED_CONFIGURATIONS RELEASE
                                       IMPORTED_LOCATION "${ZLIB_LIBRARY_RELEASE}")
    endif()
    if(ZLIB_LIBRARY_DEBUG)
      set_target_properties(Zlib::Zlib PROPERTIES
                                       IMPORTED_CONFIGURATIONS DEBUG
                                       IMPORTED_LOCATION "${ZLIB_LIBRARY_DEBUG}")
    endif()
    set_target_properties(Zlib::Zlib PROPERTIES
                                     INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}")
    if(TARGET zlib)
      add_dependencies(Zlib::Zlib zlib)
    endif()
  endif()
  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP Zlib::Zlib)
endif()

mark_as_advanced(ZLIB_INCLUDE_DIR ZLIB_LIBRARY)
