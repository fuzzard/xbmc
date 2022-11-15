# FindPythonModule-Pillow
# --------
# Finds/Builds Pillow Python package
#
# This module will build the python module on the system
#
# --------
#
# This module will define the following variables:
#
# ToDo: target/variable info
#
# --------
#

include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE_LC pythonmodule-pil)

SETUP_BUILD_VARS()

if(${CORE_SYSTEM_NAME} MATCHES "windows")
  set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/10-win-cmake.patch"
              "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/11-win-uwpsupport.patch")
else()
  set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/pillow-crosscompile.patch")
endif()

generate_patchcommand("${patches}")

if(${CORE_SYSTEM_NAME} MATCHES "windows")
  # Todo windows build - cmake based off kodi-deps
  if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
      set(ADDITIONAL_ARGS "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}" "-DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
  endif()

  # Temp? Build with NMake Makefiles to force build type (RelWithDebInfo). Release fails due to prebuilt
  # dependencies not linking correctly. Change this when all required deps are also built from source
  set(PYTHONMODULE-PIL_GENERATOR CMAKE_GENERATOR "NMake Makefiles")
  set(PYTHONMODULE-PIL_GENERATOR_PLATFORM "")
  set(PYTHONMODULE-PIL_BUILD_TYPE RelWithDebInfo)

  set(CMAKE_ARGS -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}
                 -DDEPENDS_PATH=${DEPENDS_PATH}
                 -DCMAKE_INSTALL_PREFIX=${DEPENDS_PATH}
                 ${ADDITIONAL_ARGS})
else()

  # Todo: Find_package for following depends, and populte root dirs if found
  #"JPEG_ROOT=${DEPENDS_PATH}"
  #"FREETYPE_ROOT=${DEPENDS_PATH}"
  #"HARFBUZZ_ROOT=${DEPENDS_PATH}"
  #"FRIBIDI_ROOT=${DEPENDS_PATH}"
  #"ZLIB_ROOT=${ZLIB_ROOT}"

  set(LDFLAGS ${CMAKE_EXE_LINKER_FLAGS})
  set(LDSHARED "${CMAKE_C_COMPILER} -shared")
  set(ZLIB_ROOT "${DEPENDS_PATH}")
  set(PYTHONPATH "${PYTHON_SITE_PKG}")

  if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    if(CPU STREQUAL arm64)
      set(CFLAGS "${CMAKE_C_FLAGS} -target arm64-apple-darwin")
      set(LDFLAGS "${CMAKE_EXE_LINKER_FLAGS} -target arm64-apple-darwin")
    endif()

    if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
      # ToDo: Do we genuinely need this?
      set(PYTHONPATH "${DEPENDS_PATH}/share/${APP_NAME}/addons/script.module.pil:${PYTHON_SITE_PKG}")
    endif()

    set(LDSHARED "${CMAKE_C_COMPILER} -bundle -undefined dynamic_lookup ${LDFLAGS}")
    set(ZLIB_ROOT "${SDKROOT}/usr")
  elseif(CORE_SYSTEM_NAME STREQUAL android)
    set(LDFLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${CMAKE_BINARY_DIR} -l${APP_NAME_LC} -lm")

    # ToDo: Do we genuinely need this?
    set(PYTHONPATH "${DEPENDS_PATH}/share/${APP_NAME}/addons/script.module.pil:${PYTHON_SITE_PKG}")
  endif()

  # Prepare buildenv - we need custom CFLAGS/LDFLAGS not in Toolchain.cmake
  set(PYMOD_TARGETENV "AS=${CMAKE_AS}"
                      "AR=${CMAKE_AR}"
                      "CC=${CMAKE_C_COMPILER}"
                      "CXX=${CMAKE_CXX_COMPILER}"
                      "NM=${CMAKE_NM}"
                      "LD=${CMAKE_LINKER}"
                      "STRIP=${CMAKE_STRIP}"
                      "RANLIB=${CMAKE_RANLIB}"
                      "OBJDUMP=${CMAKE_OBJDUMP}"
                      "CPPFLAGS=${CMAKE_CPP_FLAGS}"
                      "PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR}"
                      "PKG_CONFIG_PATH="
                      "PKG_CONFIG_SYSROOT_DIR=${SDKROOT}"
                      "AUTOM4TE=${AUTOM4TE}"
                      "AUTOMAKE=${AUTOMAKE}"
                      "AUTOCONF=${AUTOCONF}"
                      "ACLOCAL=${ACLOCAL}"
                      "ACLOCAL_PATH=${ACLOCAL_PATH}"
                      "AUTOPOINT=${AUTOPOINT}"
                      "AUTOHEADER=${AUTOHEADER}"
                      "LIBTOOL=${LIBTOOL}"
                      "LIBTOOLIZE=${LIBTOOLIZE}"
                      # These are additional/changed compared to PROJECT_TARGETENV
                      "CFLAGS=${CFLAGS}"
                      "LDFLAGS=${LDFLAGS}"
                      "LDSHARED=${LDSHARED}"
                      "PYTHONPATH=${PYTHONPATH}"
                      "JPEG_ROOT=${DEPENDS_PATH}"
                      "FREETYPE_ROOT=${DEPENDS_PATH}"
                      "HARFBUZZ_ROOT=${DEPENDS_PATH}"
                      "FRIBIDI_ROOT=${DEPENDS_PATH}"
                      "ZLIB_ROOT=${ZLIB_ROOT}"
                      "PYTHONXINCLUDE=${DEPENDS_PATH}/include/python${PYTHON_VERSION}"
                      )

  set(BYPASS_DEP_BUILDENV ON)

  # Set Target Configure command
  # Must be "" if no step required otherwise will try and use cmake command
  set(CONFIGURE_COMMAND COMMAND ${CMAKE_COMMAND} -E touch <SOURCE_DIR>/.separate_namespace)

  set(BUILD_COMMAND COMMAND ${CMAKE_COMMAND} -E touch <SOURCE_DIR>/.separate_namespace
                    COMMAND ${CMAKE_COMMAND} -E env ${PYMOD_TARGETENV} ${PROJECT_BUILDENV}
                            ${Python3_EXECUTABLE} setup.py build_ext --plat-name ${OS}-${CPU} 
                                                                     --disable-jpeg2000
                                                                     --disable-webp
                                                                     --disable-imagequant
                                                                     --disable-tiff
                                                                     --disable-webp
                                                                     --disable-webpmux
                                                                     --disable-xcb
                                                                     --disable-lcms
                                                                     --disable-platform-guessing
                        install --install-lib ${PYTHON_SITE_PKG})
 
  # ToDo: empty install_command possible?
  set(INSTALL_COMMAND COMMAND ${CMAKE_COMMAND} -E env ${PYMOD_TARGETENV} ${PROJECT_BUILDENV} echo Empty Install_command)
  set(BUILD_IN_SOURCE 1)

endif()

BUILD_DEP_TARGET()

if(NOT ${CORE_SYSTEM_NAME} MATCHES "windows")
  # ToDo: Doesnt work as a COMMAND in the install step. Maybe add as a custom extra step?
  # Extract egg step
  add_custom_command(TARGET ${MODULE_LC} POST_BUILD
                     COMMAND unzip -o ${PYTHON_SITE_PKG}/Pillow-*.egg -d ${PYTHON_SITE_PKG} && rm -rf ${PYTHON_SITE_PKG}/Pillow-*.egg || (exit 0))

  if(CORE_SYSTEM_NAME STREQUAL android)

    #set(SED_FLAG -i)

    # ToDo: check build host system darwin
    #ifeq (darwin, $(findstring darwin, $(BUILD)))
      set(SED_FLAG -i \'\')
    #endif

    add_custom_command(TARGET ${MODULE_LC} POST_BUILD
                       COMMAND sed ${SED_FLAG} -e \'s\/import sys\/import os, sys \/\' 
                                               -e \'\/__file__\/ s\/_imaging\/lib_imaging\/g\'
                                               -e \'s\/pkg_resources.resource_filename\(__name__\,\/os.path.join\(os.environ\[\"KODI_ANDROID_LIBS\"\], \/\'
                                                  ${PYTHON_SITE_PKG}/Pillow/PIL/_imaging*.py)
  endif()
endif()

add_dependencies(${MODULE_LC} Python3::Python)

if(CORE_SYSTEM_NAME STREQUAL android)
  add_dependencies(${MODULE_LC} ${APP_NAME_LC})
else()
  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP pythonmodule-pil)
endif()

# ToDo: Setup Target PythonModule::PyCryptodome
# Have modules in a single namespace, eg PythonModule::Pillow, etc

# ToDo: Maybe change dep for pythonmodules. They arent required for libkodi, but are required for
#       bundle/export
#
