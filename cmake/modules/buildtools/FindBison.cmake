# FindFlatC
# --------
# Find Bison executable
#
# This will define the following target:
#
#   bison::bison - The bison executable

if(NOT TARGET bison::bison)

  macro(buildbison)
    # Override build type detection and always build as release
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_BUILD_TYPE Release)
  
    if(NATIVEPREFIX)
      set(INSTALL_DIR "${NATIVEPREFIX}/bin")

      # Winflexbison has a horrible cmake install, explicitly add bin dir
      if(WIN32 OR WINDOWS_STORE)
        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${NATIVEPREFIX}/bin)
      else()
        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${NATIVEPREFIX})
      endif()
    else()
      set(INSTALL_DIR "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/bin")
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR})
    endif()
  
    if(WIN32 OR WINDOWS_STORE)
      # Set host build info for buildtool
      if(EXISTS "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
        set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_TOOLCHAIN_FILE "${NATIVEPREFIX}/share/Toolchain-Native.cmake")
      endif()

      # Make sure we generate for host arch, not target
      set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_GENERATOR_PLATFORM CMAKE_GENERATOR_PLATFORM ${HOSTTOOLSET})
  
      set(BISON_EXECUTABLE ${INSTALL_DIR}/win_bison.exe)
  
      set(CMAKE_ARGS -DDUMMY_ARGS=ON)
    else()
      set(BISON_EXECUTABLE ${INSTALL_DIR}/bison)
  
      if (CMAKE_HOST_SYSTEM_NAME MATCHES "(Free|Net|Open)BSD")
        find_program(MAKE_EXECUTABLE gmake)
      endif()
      find_program(MAKE_EXECUTABLE make REQUIRED)
  
      find_file(NATIVE_CONFIG_SITE "config.site" PATHS "${NATIVEPREFIX}/share" NO_CMAKE_FIND_ROOT_PATH REQUIRED)

      set(CONFIGURE_COMMAND ./configure
                            --prefix=${NATIVEPREFIX}
                            CC=${CC_FOR_BUILD}
                            CXX=${CXX_FOR_BUILD}
                            LD=${LD_FOR_BUILD}
                            AR=${AR_FOR_BUILD}
                            RANLIB=${RANLIB_FOR_BUILD}
                            NM=${NM_FOR_BUILD}
                            STRIP=${STRIP_FOR_BUILD}
                            CFLAGS=${CFLAGS_FOR_BUILD}
                            CXXFLAGS=${CFLAGS_FOR_BUILD}
                            CPPFLAGS=${CFLAGS_FOR_BUILD}
                            CONFIG_SITE=${NATIVE_CONFIG_SITE}
                            LDFLAGS=${LDFLAGS_FOR_BUILD})
  
        set(BUILD_COMMAND ${MAKE_EXECUTABLE})
        set(INSTALL_COMMAND ${MAKE_EXECUTABLE} install)
        set(BUILD_IN_SOURCE 1)
    endif()
  
    set(BUILD_BYPRODUCTS ${BISON_EXECUTABLE})
    set(BISON_VERSION ${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER})
  
    BUILD_DEP_TARGET()
  endmacro()

  include(${CMAKE_SOURCE_DIR}/cmake/scripts/common/ModuleHelpers.cmake)

  # Check for existing Bison.
  find_program(BISON_EXECUTABLE NAMES bison win_bison
                                HINTS ${NATIVEPREFIX}/bin
                                NO_CACHE)

  if(BISON_EXECUTABLE)
    execute_process(COMMAND "${BISON_EXECUTABLE}" -V
                    OUTPUT_VARIABLE BISON_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    string(REGEX REPLACE ".*\\(GNU Bison\\)[^0-9.]*\([0-9.]+\).*" "\\1" BISON_VERSION "${BISON_VERSION}")
  endif()

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC bison)
  set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_LIB_TYPE native)
  if(WIN32)
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_MODULE_LOCATION winflexbison)
  else()
    set(${${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC}_MODULE_LOCATION bison)
  endif()

  SETUP_BUILD_VARS()

  if(NOT BISON_EXECUTABLE OR
      ("${BISON_VERSION}" VERSION_LESS "${${${CMAKE_FIND_PACKAGE_NAME}_MODULE}_VER}"))
    buildbison()
  endif()

  include(FindPackageMessage)
  find_package_message(FlatC "Found Bison: ${BISON_EXECUTABLE} (found version \"${BISON_VERSION}\")" "[${BISON_EXECUTABLE}][${BISON_VERSION}]")

  add_executable(bison::bison IMPORTED)
  set_target_properties(bison::bison PROPERTIES
                                     IMPORTED_LOCATION "${BISON_EXECUTABLE}"
                                     FOLDER "External Projects")

  if(TARGET bison)
    add_dependencies(bison::bison bison)
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
    if(NOT TARGET bison)
      buildbison()
      set_target_properties(bison PROPERTIES EXCLUDE_FROM_ALL TRUE)
    endif()
  endif()
endif()
