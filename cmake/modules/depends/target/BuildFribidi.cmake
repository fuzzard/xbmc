include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE_LC fribidi)

SETUP_BUILD_VARS()

# Dependency requires meson-cross-file
find_file(MESON-CROSS "cross-file.meson" PATHS "${DEPENDS_PATH}/share" NO_CMAKE_FIND_ROOT_PATH REQUIRED)

# Todo: Set host executable in findpython.cmake and make this redundant
# ignore target bin location. we need host executable
# default search paths will look in both host and target build dirs
set(CMAKE_IGNORE_PATH ${DEPENDS_PATH}/bin)
find_package(Python3 EXACT ${PYTHON_VERSION}
                     COMPONENTS Interpreter
                     REQUIRED)
unset(CMAKE_IGNORE_PATH)

# Todo find Ninja and meson executables as Find modules
find_program(Meson_EXECUTABLE NAMES meson meson.py)
find_program(Ninja_EXECUTABLE NAMES ninja)

set(FRIBIDI_LIBRARY ${DEPENDS_PATH}/lib/libfribidi.a CACHE INTERNAL "" FORCE)
set(FRIBIDI_INCLUDE_DIR ${DEPENDS_PATH}/include/fribidi CACHE INTERNAL "" FORCE)
set(FRIBIDI_VERSION ${${MODULE}_VERSION} CACHE INTERNAL "" FORCE)
set(PC_FRIBIDI_CFLAGS -I${FRIBIDI_INCLUDE_DIR} CACHE INTERNAL "" FORCE)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
  set(MESON_BUILD_TYPE debug)
else()
  set(MESON_BUILD_TYPE release)
endif()

# Set Target Configure command
set(CMD_CONFIGURE CONFIGURE_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${SETBUILDENV}
                                    ${Python3_EXECUTABLE} ${Meson_EXECUTABLE}
                                    --buildtype=${MESON_BUILD_TYPE}
                                    --prefix=${DEPENDS_PATH}
                                    -Ddocs=false
                                    -Dtests=false
                                    -Dbin=false
                                    -Ddefault_library=static
                                    --cross-file ${DEPENDS_PATH}/share/cross-file.meson . build
                  )

# Set Target Build command
set(CMD_BUILD BUILD_COMMAND ${Ninja_EXECUTABLE} -v)

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND ${Ninja_EXECUTABLE} -v install)

# Set Target Byproduct
set(BYPRODUCT BUILD_BYPRODUCTS ${FRIBIDI_LIBRARY})

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

set(FRIBIDI_FOUND TRUE)
