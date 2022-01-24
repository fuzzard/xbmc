include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

find_package(Python REQUIRED)

set(MODULE_LC pythonmodule-pycryptodome)

SETUP_BUILD_VARS()

set(CFLAGS ${CMAKE_C_FLAGS})
set(LDFLAGS ${CMAKE_EXE_LINKER_FLAGS})
set(LDSHARED "$(CMAKE_C_COMPILER) -shared")

if(APPLE)
  set(LDSHARED "${CMAKE_C_COMPILER} -bundle -undefined dynamic_lookup ${LDFLAGS}")
endif()

set(PLATFORM_PATCH COMMAND "")

if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
  list(APPEND CFLAGS "-target arm64-apple-darwin")
elseif(CORE_SYSTEM_NAME STREQUAL android)
  list(APPEND LDFLAGS "-L${DEPENDS_PATH}/lib/dummy-lib${APP_NAME_LC}/ -l${APP_NAME_LC} -lm")
  set(PLATFORM_PATCH COMMAND patch -p1 -i "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/02-android-dlopen.patch")
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
                    ${PYTHONPATH}
                    )

set(PYMODENV ${CMAKE_COMMAND} -E env ${PYMOD_TARGETENV} ${PROJECT_BUILDENV})


set(CMD_PATCH PATCH_COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/01-nosetuptool.patch
                          COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/03-obey-crosscompileflags.patch
                          ${PLATFORM_PATCH
              )


# Set Target Configure command
# Must be "" if no step required otherwise will try and use cmake command
set(CMD_CONFIGURE CONFIGURE_COMMAND "")

# Set Target Build command
set(CMD_BUILD BUILD_COMMAND set "PATH=${ENVPATH}"
                          COMMAND ${CMAKE_COMMAND} -E touch <SOURCE_DIR>/.separate_namespace
                          COMMAND ${PYMODENV}
                          ${Python3_EXECUTABLE} setup.py build_ext --plat-name ${OS}-${CPU}
              )

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${PYMODENV}
                                    ${Python3_EXECUTABLE} setup.py install --prefix=${DEPENDS_PATH}
                )

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

add_dependencies(${MODULE_LC} python3)
