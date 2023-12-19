# FindPythonModule-Setuptools
# --------
# Finds/Builds Setuptools Python package
#
# This module will build the python module on the system
#
# --------
#
# This module will define the following variables:
#
# Python::Setuptools - The Setuptools python module
#
# --------
#

if(NOT TARGET Python::Setuptools)

  #Todo: detect existing setuptools installation of target python
  include(cmake/scripts/common/ModuleHelpers.cmake)

  find_package(PythonInterpreter REQUIRED)
  find_package(Python REQUIRED)

  set(MODULE_LC pythonmodule-setuptools)

  SETUP_BUILD_VARS()

  set(BYPASS_DEP_BUILDENV ON)

  # Set Target Configure command
  # Must be "" if no step required otherwise will try and use cmake command
  set(CONFIGURE_COMMAND COMMAND "")

  # Set Target Build command
  # Must be "" if no step required otherwise will try and use cmake command
  set(BUILD_COMMAND COMMAND "")

  # Set Target Install command
  set(INSTALL_COMMAND ${CMAKE_COMMAND} -E env ${PROJECT_TARGETENV} ${PROJECT_BUILDENV} PYTHONPATH="$(PYTHON_SITE_PKG)"
                      ${PYTHON_EXECUTABLE} setup.py install --prefix=${DEPENDS_PATH})

  set(BUILD_IN_SOURCE 1)
  BUILD_DEP_TARGET()

  if(NOT ${CORE_SYSTEM_NAME} MATCHES "windows")
    add_custom_command(TARGET ${MODULE_LC} POST_BUILD
                       COMMAND find ${PYTHON_SITE_PKG}/*setuptools* -type f -name \"*.exe\" -exec rm -f \{\} \\;)
  endif()

  add_library(Python::Setuptools UNKNOWN IMPORTED)
  add_dependencies(Python::Setuptools ${MODULE_LC})
  add_dependencies(${MODULE_LC} ${APP_NAME_LC}::Python)

  message(STATUS "Building python module Setuptools internally")

  if(NOT TARGET python-binarymodules)
    add_custom_target(python-binarymodules)
    set_target_properties(python-binarymodules PROPERTIES EXCLUDE_FROM_ALL TRUE)
  endif()

  add_dependencies(python-binarymodules Python::Setuptools)
endif()
