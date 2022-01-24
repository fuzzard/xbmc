include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE_LC libass)

SETUP_BUILD_VARS()

# Do we do a find package or just add_dependencies for a buildmodule?
#find_package(FriBidi REQUIRED)

set(ASS_LIBRARY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/depends/target/lib/libass.a)
set(ASS_INCLUDE_DIR ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/depends/target/include)
set(ASS_VERSION ${${MODULE}_VERSION})

# Set Target Configure command
set(CMD_CONFIGURE CONFIGURE_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${SETBUILDENV} autoreconf -vif
                            COMMAND ${SETBUILDENV}
                                    ./configure
                                    --host=${HOST}
                                    --prefix=${DEPENDS_PATH}
                  )

# Set Target Build command
set(CMD_BUILD BUILD_COMMAND $(MAKE))

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND $(MAKE) install)

# Set Target Byproduct
set(BYPRODUCT BUILD_BYPRODUCTS ${ASS_LIBRARY})

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

set(ASS_FOUND TRUE)

add_dependencies(${MODULE_LC} fribidi)
