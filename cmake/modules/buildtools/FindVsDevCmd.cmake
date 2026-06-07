#.rst:
# FindVsDevCmd
# -----------------
# Finds vsdevcmd.bat with current cmake version as search parameter
#
# VSDEVCMD_BAT - vsdevcmd.bat

# Find Vswhere executable
cmake_path(CONVERT "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer"
           TO_CMAKE_PATH_LIST vsinstaller
           NORMALIZE)

find_program(VSWHERE_EXECUTABLE vswhere
                                HINTS ${vsinstaller}
                                REQUIRED)

# Use vswhere to search the specific VS version currently used in this cmake project
execute_process(COMMAND "${VSWHERE_EXECUTABLE}"
                        -version [${CMAKE_VS_VERSION_BUILD_NUMBER}]
                        -property installationPath
                OUTPUT_VARIABLE vs_installpath
                OUTPUT_STRIP_TRAILING_WHITESPACE)

cmake_path(CONVERT "${vs_installpath}/Common7/Tools/VsDevCmd.bat"
           TO_CMAKE_PATH_LIST VSDEVCMD_BAT
           NORMALIZE)

if(NOT "${VSDEVCMD_BAT}" STREQUAL "")
  set(VSDEVCMD_BAT ${VSDEVCMD_BAT} CACHE FILEPATH "Vsdevcmd.bat location")
  
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(VsDevCmd
                                    FAIL_MESSAGE "Vsdevcmd.bat could not be found in ${vs_installpath}/Common7/Tools"
                                    REQUIRED_VARS VSDEVCMD_BAT)
  
  mark_as_advanced(VSDEVCMD_BAT)
else()
  if(VsDevCmd_FIND_REQUIRED)
    message(FATAL_ERROR "Vsdevcmd.bat could not be found in ${vs_installpath}/Common7/Tools")
  endif()
endif()
