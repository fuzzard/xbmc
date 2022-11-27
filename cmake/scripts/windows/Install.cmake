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
