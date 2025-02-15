#.rst:
# FindSWIG
# --------
# Finds the SWIG executable
#
# This will define the following TARGET:
#
# SWIG::SWIG - the SWIG executable

if(NOT TARGET SWIG::SWIG)

  macro(buildswig)
    find_package(Bison REQUIRED)
    find_package(Host_PCRE2 REQUIRED)

    # Override build type detection and always build as release
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_TYPE Release)

    if(NATIVEPREFIX)
      set(INSTALL_DIR "${NATIVEPREFIX}/bin")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${NATIVEPREFIX})
    else()
      set(INSTALL_DIR "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/bin")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR})
    endif()

    set(patches "${CORE_SOURCE_DIR}/tools/depends/native/${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}/01-all-cmake-pcre-static-lib.patch")

    generate_patchcommand("${patches}")

    set(CMAKE_ARGS -DDUMMY_ARGS=OFF)

    # Set host build info for buildtool
    if(EXISTS "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_TOOLCHAIN_FILE "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
    endif()

    if(WIN32 OR WINDOWS_STORE)
      # Make sure we generate for host arch, not target
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_GENERATOR_PLATFORM CMAKE_GENERATOR_PLATFORM ${HOSTTOOLSET})

      # Must passthrough PCRE2 static flags. THe swig FindPCRE2 module is extremely basic, and doesnt use the
      # PCRE2 config to pull in relevant information
      list(APPEND CMAKE_ARGS -DCMAKE_C_FLAGS=/DPCRE2_STATIC
                             -DCMAKE_CXX_FLAGS=/DPCRE2_STATIC)

      set(SWIG_EXECUTABLE ${INSTALL_DIR}/swig.exe)
    else()
      set(SWIG_EXECUTABLE ${INSTALL_DIR}/swig)
    endif()

    set(BUILD_BYPRODUCTS ${SWIG_EXECUTABLE})
    set(SWIG_VERSION ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})

    BUILD_DEP_TARGET()

    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} bison::bison)
    add_dependencies(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC} HOST::PCRE2)
  endmacro()

  include(${CMAKE_SOURCE_DIR}/cmake/scripts/common/ModuleHelpers.cmake)

  find_program(SWIG_EXECUTABLE NAMES swig4.0 swig3.0 swig2.0 swig
                               NO_CACHE
                               PATH_SUFFIXES swig
                               HINTS ${NATIVEPREFIX}/bin)

  if(SWIG_EXECUTABLE)
    execute_process(COMMAND ${SWIG_EXECUTABLE} -version
                    OUTPUT_VARIABLE SWIG_version_output
                    ERROR_VARIABLE SWIG_version_output
                    RESULT_VARIABLE SWIG_version_result)
    string(REGEX REPLACE ".*SWIG Version[^0-9.]*\([0-9.]+\).*" "\\1"
           SWIG_VERSION "${SWIG_version_output}")
  endif()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC swig)
  set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_LIB_TYPE native)

  SETUP_BUILD_VARS()

  if(NOT SWIG_EXECUTABLE OR
      ("${SWIG_VERSION}" VERSION_LESS "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER}"))
    buildswig()
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(SWIG
                                    REQUIRED_VARS SWIG_EXECUTABLE
                                    VERSION_VAR SWIG_VERSION)

  if(SWIG_FOUND)
    add_executable(SWIG::SWIG IMPORTED GLOBAL)
    set_target_properties(SWIG::SWIG PROPERTIES
                                     IMPORTED_LOCATION "${SWIG_EXECUTABLE}"
                                     VERSION "${SWIG_VERSION}")

    if(TARGET swig)
      add_dependencies(${CMAKE_FIND_PACKAGE_NAME}::${CMAKE_FIND_PACKAGE_NAME} swig)
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
      if(NOT TARGET swig)
        buildswig()
        set_target_properties(swig PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
    endif()
  else()
    if(SWIG_FIND_REQUIRED)
      message(FATAL_ERROR "Swig executable was not found.")
    endif()
  endif()
endif()
