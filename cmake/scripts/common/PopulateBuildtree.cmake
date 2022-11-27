include(${CORE_SOURCE_DIR}/cmake/scripts/common/Macros.cmake)

message(STATUS "PostBuild copy to buildtree")

# copy files to build tree
copy_files_from_filelist_to_buildtree(${CMAKE_SOURCE_DIR}/cmake/installdata/common/*.txt
                                      ${CMAKE_SOURCE_DIR}/cmake/installdata/${CORE_SYSTEM_NAME}/*.txt)
