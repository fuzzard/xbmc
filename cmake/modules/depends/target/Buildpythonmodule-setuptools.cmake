include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

find_package(Python REQUIRED)

set(MODULE_LC pythonmodule-setuptools)

SETUP_BUILD_VARS()

# Set Target Configure command
# Must be "" if no step required otherwise will try and use cmake command
set(CMD_CONFIGURE CONFIGURE_COMMAND "")

# Set Target Build command
# Must be "" if no step required otherwise will try and use cmake command
set(CMD_BUILD BUILD_COMMAND "")

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${PYTHONPATH}
                                    ${Python3_EXECUTABLE} setup.py install
                                    --prefix=${DEPENDS_PATH}
                )

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

add_dependencies(${MODULE_LC} python3)
