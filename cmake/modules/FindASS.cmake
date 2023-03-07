#.rst:
# FindASS
# -------
# Finds the ASS library
#
# This will define the following variables::
#
# ASS_FOUND - system has ASS
# ASS_INCLUDE_DIRS - the ASS include directory
# ASS_LIBRARIES - the ASS libraries
#
# and the following imported targets::
#
#   ASS::ASS   - The ASS library

if(CORE_SYSTEM_NAME MATCHES windows)
  # CMake config search for windows
  find_package(LIBASS CONFIG QUIET)

  set(ASS_VERSION ${LIBASS_VERSION})
else()
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_ASS libass QUIET)
  endif()

  set(ASS_VERSION ${PC_ASS_VERSION})
endif()

# Pkgconfig or cmake version found, search for lib/include
if(ASS_VERSION)
  find_path(ASS_INCLUDE_DIR NAMES ass/ass.h
                            PATHS ${PC_ASS_INCLUDEDIR}
                                  ${DEPENDS_PATH}/include)
  find_library(ASS_LIBRARY NAMES ass libass
                           PATHS ${PC_ASS_LIBDIR}
                                 ${DEPENDS_PATH}/lib)
endif()

if(ENABLE_INTERNAL_LIBASS)

  get_libversion_data("libass" "target")

  if((ASS_VERSION VERSION_LESS ${LIB_LIBASS_VER}) OR NOT ASS_LIBRARY)

    include(cmake/scripts/common/ModuleHelpers.cmake)

    find_package(LibUniBreak MODULE REQUIRED)

    set(MODULE_LC libass)
    SETUP_BUILD_VARS()

    find_program(AUTORECONF autoreconf REQUIRED)
    if (CMAKE_HOST_SYSTEM_NAME MATCHES "(Free|Net|Open)BSD")
      find_program(MAKE_EXECUTABLE gmake)
    endif()
    find_program(MAKE_EXECUTABLE make REQUIRED)

    if(CORE_SYSTEM_NAME STREQUAL android)
      # Required for SDK API Levels 21/22
      # When we bump minimum to API 23, we can remove this flag
      set(LIBASS_FLAGS "-lstdc++")

      if(CPU STREQUAL "i686")
        set(EXTRA_FLAGS "ASFLAGS=-DPIC=1")
      endif()
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      set(LIBASS_BYPRODUCT_EXTENSION "dylib")

      if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
        
      endif()
    endif()

    set(CONFIGURE_COMMAND ${AUTORECONF} -vif
                  COMMAND ./configure
                          --host=${ARCH}
                          --prefix=${DEPENDS_PATH}
                          "LDFLAGS=${CMAKE_EXE_LINKER_FLAGS} ${LIBASS_FLAGS}"
                          ${EXTRA_FLAGS})

    # libass only provides asm for x86/x86_64.
    # Make sure nasm is on path. This is an issue specifically with KODI_DEPENDSBUILD
    if(CPU STREQUAL x86_64 OR CPU MATCHES "i.86")
      find_program(NASM nasm HINTS ${NATIVEPREFIX}/bin REQUIRED)
      cmake_path(REMOVE_FILENAME NASM OUTPUT_VARIABLE NASM_BIN)
      set(BUILD_PATHBIN PATH=${NASM_BIN}:$ENV{PATH})
    endif()

    set(BUILD_COMMAND ${CMAKE_COMMAND} -E env ${DEP_BUILDENV} ${BUILD_PATHBIN} ${MAKE_EXECUTABLE})
    set(INSTALL_COMMAND ${MAKE_EXECUTABLE} install)
    set(BUILD_IN_SOURCE 1)

    BUILD_DEP_TARGET()

    set(ASS_LIBRARY ${${MODULE}_LIBRARY})
    set(ASS_INCLUDE_DIR ${${MODULE}_INCLUDE_DIR})
    set(ASS_VERSION ${${MODULE}_VER})
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ASS
                                  REQUIRED_VARS ASS_LIBRARY ASS_INCLUDE_DIR
                                  VERSION_VAR ASS_VERSION)

if(ASS_FOUND)
  if(NOT TARGET ASS::ASS)
    add_library(ASS::ASS UNKNOWN IMPORTED)
    set_target_properties(ASS::ASS PROPERTIES
                                   IMPORTED_LOCATION "${ASS_LIBRARY}"
                                   INTERFACE_INCLUDE_DIRECTORIES "${ASS_INCLUDE_DIR}")

    if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
      # Shared lib, not required
      #  target_link_options(ASS::ASS INTERFACE "-framework CoreText")
      # Static lib requires below
      #set_property(TARGET ASS::ASS PROPERTY
      #                             STATIC_LIBRARY_OPTIONS "-framework CoreText")
    endif()

    set(ASS_LIBRARIES ASS::ASS)
    set(ASS_INCLUDE_DIRS ASS::ASS)

    if(TARGET UNIBREAK::UNIBREAK)
      list(APPEND ASS_LIBRARIES UNIBREAK::UNIBREAK)
    endif()

    if(TARGET libass)
      add_dependencies(ASS::ASS libass)
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP ASS::ASS)
  endif()
endif()

mark_as_advanced(ASS_INCLUDE_DIR ASS_LIBRARY)
