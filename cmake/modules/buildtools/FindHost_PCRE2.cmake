#.rst:
# FindPCRE2
# --------
# Finds the PCRE2 library
#
# This will define the following imported target::
#
#   HOST::PCRE2    - The PCRE2 library (Host machine architecture)

if(NOT TARGET HOST::PCRE2)

  macro(buildHostPCRE2)

    # Override build type detection and always build as release
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_TYPE Release)

    if(NATIVEPREFIX)
      set(INSTALL_DIR "${NATIVEPREFIX}/bin")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${NATIVEPREFIX})
    else()
      set(INSTALL_DIR "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/bin")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR})
    endif()

    # Set host build info for buildtool
    if(EXISTS "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_TOOLCHAIN_FILE "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
    endif()

    if(WIN32 OR WINDOWS_STORE)
      # Make sure we generate for host arch, not target
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_GENERATOR_PLATFORM CMAKE_GENERATOR_PLATFORM ${HOSTTOOLSET})
    endif()

    set(HOST_PCRE2_VERSION ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})

    set(CMAKE_ARGS -DBUILD_STATIC_LIBS=ON
                   -DPCRE2_STATIC_PIC=ON
                   -DPCRE2_BUILD_PCRE2_8=ON
                   -DPCRE2_BUILD_PCRE2_16=OFF
                   -DPCRE2_BUILD_PCRE2_32=OFF
                   -DPCRE_NEWLINE=ANYCRLF
                   -DPCRE2_SUPPORT_UNICODE=ON
                   -DPCRE2_BUILD_PCRE2GREP=OFF
                   -DPCRE2_BUILD_TESTS=OFF
                   -DENABLE_DOCS=OFF
                   -DPCRE2_SUPPORT_LIBBZ2=OFF
                   -DPCRE2_SUPPORT_LIBZ=OFF
                   -DPCRE2_SUPPORT_LIBEDIT=OFF
                   -DPCRE2_SUPPORT_LIBREADLINE=OFF
                   -DPCRE2GREP_SUPPORT_JIT=OFF
                   -DPCRE2GREP_SUPPORT_CALLOUT=OFF
                   -DPCRE2GREP_SUPPORT_CALLOUT_FORK=OFF
                   ${EXTRA_ARGS})

    set(${CMAKE_FIND_PACKAGE_NAME}_COMPILEDEFINITIONS PCRE2_STATIC)

    BUILD_DEP_TARGET()
  endmacro()

  include(${CMAKE_SOURCE_DIR}/cmake/scripts/common/ModuleHelpers.cmake)

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC host_pcre2)
  set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_MODULE_LOCATION pcre2)
  set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_LIB_TYPE native)

  SETUP_BUILD_VARS()

  # For host libs, we dont want to create any targets that could pollute the target namespace
  # We just grep a known cmake config version file to populate existing version.
  if(EXISTS ${NATIVEPREFIX}/cmake/pcre2-config-version.cmake)
    file(READ  ${NATIVEPREFIX}/cmake/pcre2-config-version.cmake pcre_cmake_ver_file)
    string(REGEX REPLACE ".*set\\(PACKAGE_VERSION[^0-9.]*\([0-9.]+\)\\).*" "\\1" HOST_PCRE2_VERSION "${pcre_cmake_ver_file}")
  endif()

  if((HOST_PCRE2_VERSION VERSION_LESS ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER} AND ENABLE_INTERNAL_PCRE2) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_PCRE2))
    buildHostPCRE2()
  else()
    # For a host lib, we dont want to create targets to pollute potential target system libs
    # We intentally do a find path/library to locate files
    find_path(HOST_PCRE2_INCLUDE_DIR pcre2.h
                                     HINTS ${NATIVEPREFIX}/include)
    find_library(HOST_PCRE2_LIBRARY_RELEASE NAMES pcre2-8-static pcre2-8
                                            HINTS ${NATIVEPREFIX}/lib)
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(HOST_PCRE2)
  unset(HOST_PCRE2_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Host_PCRE2
                                    REQUIRED_VARS HOST_PCRE2_LIBRARY HOST_PCRE2_INCLUDE_DIR
                                    VERSION_VAR HOST_PCRE2_VERSION)

  if(Host_PCRE2_FOUND)
    add_library(HOST::PCRE2 UNKNOWN IMPORTED)
    if(HOST_PCRE2_LIBRARY_RELEASE)
      set_target_properties(HOST::PCRE2 PROPERTIES
                                        IMPORTED_CONFIGURATIONS RELEASE
                                        IMPORTED_LOCATION_RELEASE "${HOST_PCRE2_LIBRARY_RELEASE}")
    endif()
    if(HOST_PCRE2_LIBRARY_DEBUG)
      set_target_properties(HOST::PCRE2 PROPERTIES
                                        IMPORTED_LOCATION_DEBUG "${HOST_PCRE2_LIBRARY_DEBUG}")
      set_property(TARGET HOST::PCRE2 APPEND PROPERTY
                                             IMPORTED_CONFIGURATIONS DEBUG)
    endif()
    set_target_properties(HOST::PCRE2 PROPERTIES
                                      INTERFACE_INCLUDE_DIRECTORIES "${HOST_PCRE2_INCLUDE_DIR}")

    # Add interface compile definitions. This will usually come from an INTERNAL build being required.
    if(${CMAKE_FIND_PACKAGE_NAME}_COMPILEDEFINITIONS)
      set_property(TARGET HOST::PCRE2 APPEND PROPERTY
                                             INTERFACE_COMPILE_DEFINITIONS ${${CMAKE_FIND_PACKAGE_NAME}_COMPILEDEFINITIONS})
    endif()

    if(TARGET host_pcre2)
      add_dependencies(HOST::PCRE2 host_pcre2)
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
      if(NOT TARGET host_pcre2)
        buildHostPCRE2()
        set_target_properties(host_pcre2 PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
    endif()

  else()
    if(Host_PCRE2_FIND_REQUIRED)
      message(FATAL_ERROR "PCRE2 not found for Build system.")
    endif()
  endif()
endif()
