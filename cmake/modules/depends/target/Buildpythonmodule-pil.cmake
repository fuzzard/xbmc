include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

find_package(Python REQUIRED)

set(MODULE_LC pythonmodule-pil)

SETUP_BUILD_VARS()

set(PILPATH ${PYTHON_SITE_PKG})

set(CFLAGS ${CMAKE_C_FLAGS})
set(LDFLAGS ${CMAKE_EXE_LINKER_FLAGS})
set(LDSHARED "$(CMAKE_C_COMPILER) -shared")

if(APPLE)
  set(LDSHARED "${CMAKE_C_COMPILER} -bundle -undefined dynamic_lookup")
  set(ZLIB_ROOT "ZLIB_ROOT=${SDKROOT}/usr")
endif()

if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
  list(APPEND CFLAGS "-target arm64-apple-darwin")
  set(PILPATH "${DEPENDS_PATH}/share/${APP_NAME_LC}/addons/script.module.pil")
  IF(NOT EXISTS ${PILPATH})
    make_directory(${PILPATH})
  endif()
elseif(CORE_SYSTEM_NAME STREQUAL android)
  list(APPEND LDFLAGS "-L${DEPENDS_PATH}/lib/dummy-lib${APP_NAME_LC}/ -l${APP_NAME_LC} -lm")
  set(PILPATH "${DEPENDS_PATH}/share/${APP_NAME_LC}/addons/script.module.pil")
  IF(NOT EXISTS ${PILPATH})
    make_directory(${PILPATH})
  endif()
endif()

# Prepare buildenv - we need custom CFLAGS/LDFLAGS
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
                    "PKG_CONFIG_SYSROOT_DIR=${SDKROOT}"
                    "PYTHONXINCLUDE=${DEPENDS_PATH}/include/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}"
                    ${PYTHONPATH}
                    ${ZLIB_ROOT}
                    )

set(PYMODENV ${CMAKE_COMMAND} -E env ${PYMOD_TARGETENV} ${PROJECT_BUILDENV})

# Set Target Patch command
set(CMD_PATCH PATCH_COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/pythonmodule-pil/pillow-crosscompile.patch)

# Set Target Configure command
# Must be "" if no step required otherwise will try and use cmake command
set(CMD_CONFIGURE CONFIGURE_COMMAND "")

# Set Target Build command
# Must be "" if no step required otherwise will try and use cmake command
set(CMD_BUILD BUILD_COMMAND "")

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND INSTALL_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${PYMODENV}
                                    ${Python3_EXECUTABLE} setup.py build_ext --plat-name ${OS}-${CPU} --disable-jpeg2000 --disable-webp --disable-imagequant --disable-tiff --disable-webp --disable-webpmux --disable-xcb --disable-lcms --disable-platform-guessing install --install-lib ${PILPATH}
                )

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

# Postbuild custom command
add_custom_command(TARGET ${MODULE_LC}
                   POST_BUILD
                   COMMAND unzip -o Pillow-*.egg
                   COMMAND ${CMAKE_COMMAND} -E rm -f Pillow-*.egg
                   WORKING_DIRECTORY ${PILPATH})

add_dependencies(${MODULE_LC} python3)
