# Fix UWP addons security issue caused by empty __init__.py Python Lib files packaged with Kodi
# Encapsulate fix script to allow post generation execution in the event the python lib is
# built after project generation.

file(REMOVE ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/GeneratedUWPPythonInitFix.cmake)
file(APPEND ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/GeneratedUWPPythonInitFix.cmake
"set(uwp_pythonlibinit_filepattern \"\$\{DEPENDS_PATH\}/bin/Python/Lib/__init__.py\")
file(GLOB_RECURSE uwp_pythonlibinit_foundfiles \"\$\{uwp_pythonlibinit_filepattern\}\")
foreach(uwp_pythonlibinit_file \$\{uwp_pythonlibinit_foundfiles\})
    file(SIZE \"\$\{uwp_pythonlibinit_file\}\" uwp_pythonlibinit_filesize)
    if(\$\{uwp_pythonlibinit_filesize\} EQUAL 0)
        message(\"Adding hash comment character in the following empty file: \$\{uwp_pythonlibinit_file\}\")
        file(APPEND ${uwp_pythonlibinit_file} \"#\")
    endif()
endforeach()\n")

# Change to Python3::Python target when built internal
add_custom_command(TARGET ${APP_NAME_LC} POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -DDEPENDS_PATH=${DEPENDS_PATH}
                                            -P ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/GeneratedUWPPythonInitFix.cmake
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

# Copy any files added to ExportFiles.cmake list to app target location
#
# This is done as a POST_BUILD command on the main app target. This is required to Copy
# files into the correct path for a MutliConfig Generator (VS) for a buildtype that is NOT
# known at cmake generation time.
#
# This also allows any file that doesnt exist at generation, but are built during build
# to be copied to the correct build type folder (eg Debug/RelwithBuildinfo/etc).
#
# This allows the built app target executable to be executed immediately when built, as all
# required files for a bundle are copied into the correct location
add_custom_command(TARGET ${APP_NAME_LC} POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -DCORE_SOURCE_DIR=${CMAKE_SOURCE_DIR}
                                            -DCORE_SYSTEM_NAME=${CORE_SYSTEM_NAME}
                                            -DCORE_BUILD_DIR=${CORE_BUILD_DIR}
                                            -DCORE_BINARY_DIR=${CMAKE_BINARY_DIR}
                                            -DARCH=${ARCH}
                                            -DBUNDLEDIR=$<TARGET_FILE_DIR:${APP_NAME_LC}>
                                            -P ${CMAKE_SOURCE_DIR}/cmake/scripts/common/PopulateBuildtree.cmake
                   COMMAND ${CMAKE_COMMAND} -DBUNDLEDIR=$<TARGET_FILE_DIR:${APP_NAME_LC}>
                                            -P ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/ExportFiles.cmake
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
