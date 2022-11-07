# Copy dll's and java jar to Build Dir
# This is done as a POST_BUILD command on the main app target
# This makes sure to copy any dll's that dont exist at generation, but are built during build
add_custom_command(TARGET ${APP_NAME_LC} POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -DBUNDLEDIR=$<TARGET_FILE_DIR:${APP_NAME_LC}> 
                                            -DBINSRC=${CMAKE_SOURCE_DIR}/project/BuildDependencies/${ARCH}/bin 
                                            -DCMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}
                                            -DCORE_SYSTEM_NAME=${CORE_SYSTEM_NAME}
                                            -P ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/ExportFiles.cmake
                   WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
