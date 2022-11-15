# FindPythonModule-PyCryptodome
# --------
# Finds/Builds PyCryptodome Python package
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

set(MODULE_LC pythonmodule-pycryptodome)

SETUP_BUILD_VARS()

if(${CORE_SYSTEM_NAME} MATCHES "windows")
  set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/10-win-cmake.patch"
              "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/11-win-arm64-buildfix.patch")
else()
  set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/01-nosetuptool.patch"
              "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/02-revert-ctype.pythonapi-use.patch")

  if(${CORE_SYSTEM_NAME} STREQUAL "android")
    list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/03-android-dlopen.patch")
  endif()
endif()

generate_patchcommand("${patches}")

if(${CORE_SYSTEM_NAME} MATCHES "windows")
  # Todo windows build - cmake based off kodi-deps
  if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
      set(ADDITIONAL_ARGS "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}" "-DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
  endif()

  # Temp? Build with NMake Makefiles to force build type (RelWithDebInfo). 
  # simpler build, is it quicker than an MSVC generator?
  set(PYTHONMODULE-PYCRYPTODOME_GENERATOR CMAKE_GENERATOR "NMake Makefiles")
  set(PYTHONMODULE-PYCRYPTODOME_GENERATOR_PLATFORM "")
  set(PYTHONMODULE-PYCRYPTODOME_BUILD_TYPE RelWithDebInfo)

  set(CMAKE_ARGS -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}
                 -DDEPENDS_PATH=${DEPENDS_PATH}
                 -DCMAKE_INSTALL_PREFIX=${DEPENDS_PATH}
                 -DSEPARATE_NAMESPACE=ON
                 ${ADDITIONAL_ARGS})
else()

  # We only need this for non windows platforms, as windows uses custom cmake project
  # that doesnt require python executable
  # causes recursive loop
  # find_package(Python REQUIRED)

  set(LDFLAGS ${CMAKE_EXE_LINKER_FLAGS})
  set(LDSHARED "${CMAKE_C_COMPILER} -shared")

  if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    if(CPU STREQUAL arm64)
      set(CFLAGS "${CMAKE_C_FLAGS} -target arm64-apple-darwin")
      set(LDFLAGS "${CMAKE_EXE_LINKER_FLAGS} -target arm64-apple-darwin")
    endif()
    set(LDSHARED "${CMAKE_C_COMPILER} -bundle -undefined dynamic_lookup ${LDFLAGS}")
  elseif(CORE_SYSTEM_NAME STREQUAL android)
    set(LDFLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${DEPENDS_PATH}/lib/dummy-lib${APP_NAME_LC}/ -l${APP_NAME_LC} -lm")
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
                      "PYTHONPATH=${PYTHON_SITE_PKG}"
                      )

  set(BYPASS_DEP_BUILDENV ON)

  # Set Target Configure command
  # Must be "" if no step required otherwise will try and use cmake command
  set(CONFIGURE_COMMAND COMMAND ${CMAKE_COMMAND} -E touch <SOURCE_DIR>/.separate_namespace)

  set(BUILD_COMMAND COMMAND ${CMAKE_COMMAND} -E touch <SOURCE_DIR>/.separate_namespace
                    COMMAND ${CMAKE_COMMAND} -E env ${PYMOD_TARGETENV} ${PROJECT_BUILDENV}
                            ${Python3_EXECUTABLE} setup.py build_ext --plat-name ${OS}-${CPU})

  set(INSTALL_COMMAND COMMAND ${CMAKE_COMMAND} -E env ${PYMOD_TARGETENV} ${PROJECT_BUILDENV}
                              ${Python3_EXECUTABLE} setup.py install --prefix=${DEPENDS_PATH})
  set(BUILD_IN_SOURCE 1)

endif()

BUILD_DEP_TARGET()

if(NOT ${CORE_SYSTEM_NAME} MATCHES "windows")
  # ToDo: Doesnt work as a COMMAND in the install step. Maybe add as a custom extra step?
  # Extract egg step
  add_custom_command(TARGET ${MODULE_LC} POST_BUILD
                     COMMAND mkdir -p ${PYTHON_SITE_PKG}/Cryptodome && cp -rf ${PYTHON_SITE_PKG}/pycryptodomex*.egg/Cryptodome/* ${PYTHON_SITE_PKG}/Cryptodome && rm -rf ${PYTHON_SITE_PKG}/pycryptodomex*.egg || (exit 0))
endif()

add_dependencies(${MODULE_LC} Python3::Python)

# ToDo: Setup Target PythonModule::PyCryptodome
# Have modules in a single namespace, eg PythonModule::Pillow, etc

# ToDo: Maybe change dep for pythonmodules. They arent required for libkodi, but are required for
#       bundle/export
set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP pythonmodule-pycryptodome)
