#.rst:
# FindUdfread
# --------
# Finds the udfread library
#
# This will define the following variables::
#
# UDFREAD_FOUND - system has udfread
# UDFREAD_INCLUDE_DIRS - the udfread include directory
# UDFREAD_LIBRARIES - the udfread libraries
# UDFREAD_DEFINITIONS - the udfread definitions

if(ENABLE_INTERNAL_UDFREAD)
  if(NOT TARGET dep_udfread)
    include(cmake/scripts/common/ModuleHelpers.cmake)

    set(MODULE_LC udfread)

    SETUP_BUILD_VARS()

    set(UDFREAD_VERSION ${${MODULE}_VER})

    if(WIN32 OR WINDOWS_STORE)

      # find the path to the patch executable
      find_program(PATCH_EXECUTABLE NAMES patch patch.exe REQUIRED)

      set(PATCH_COMMAND ${CMAKE_COMMAND} -E copy
                        ${CMAKE_SOURCE_DIR}/tools/depends/target/udfread/CMakeLists.txt
                        <SOURCE_DIR>
                COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/udfread/001-win-ssizet.patch
                COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/udfread/002-win-udfreadversion.patch
                COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/udfread/003-win-cmake-libconfig.patch)

      if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
        set(EXTRA_ARGS "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}" "-DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
      endif()

      # We need to set something in CMAKE_ARGS, so set install prefix as it wont
      # matter if its doubled in the cmake command
      set(CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${DEPENDS_PATH}"
                     ${EXTRA_ARGS})
    else()
      find_program(AUTORECONF autoreconf REQUIRED)

      set(CONFIGURE_COMMAND ${AUTORECONF} -vif
                    COMMAND ./configure
                              --enable-static
                              --disable-shared
                              --prefix=${DEPENDS_PATH})
      set(BUILD_COMMAND ${CMAKE_MAKE_PROGRAM})
      set(INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install)
      set(BUILD_IN_SOURCE 1)
    endif()

    BUILD_DEP_TARGET()
  endif()
else()
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_UDFREAD udfread>=1.0.0 QUIET)
  endif()

  find_path(UDFREAD_INCLUDE_DIR NAMES udfread/udfread.h
                            PATHS ${PC_UDFREAD_INCLUDEDIR})

  find_library(UDFREAD_LIBRARY_RELEASE NAMES udfread libudfread
                                       PATHS ${PC_UDFREAD_LIBDIR})

  set(UDFREAD_VERSION ${PC_UDFREAD_VERSION})
endif()

include(SelectLibraryConfigurations)
select_library_configurations(UDFREAD)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Udfread
                                  REQUIRED_VARS UDFREAD_LIBRARY UDFREAD_INCLUDE_DIR
                                  VERSION_VAR UDFREAD_VERSION)

if(UDFREAD_FOUND)
  set(UDFREAD_LIBRARIES ${UDFREAD_LIBRARY})
  set(UDFREAD_INCLUDE_DIRS ${UDFREAD_INCLUDE_DIR})
  set(UDFREAD_DEFINITIONS -DHAS_UDFREAD=1)

  if(NOT TARGET udfread)
    add_library(udfread UNKNOWN IMPORTED)
    set_target_properties(udfread PROPERTIES
                                 IMPORTED_LOCATION "${UDFREAD_LIBRARIES}"
                                 INTERFACE_INCLUDE_DIRECTORIES "${UDFREAD_INCLUDE_DIRS}")
    if(TARGET dep_udfread)
      add_dependencies(udfread dep_udfread)
    endif()
  endif()

  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP udfread)

endif()

mark_as_advanced(UDFREAD_INCLUDE_DIR UDFREAD_LIBRARY)
