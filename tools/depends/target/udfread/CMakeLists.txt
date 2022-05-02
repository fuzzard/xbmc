cmake_minimum_required(VERSION 3.15)

project(libudfread VERSION 1.1.2 LANGUAGES C)

if(MSVC)
  set(CMAKE_DEBUG_POSTFIX "d")
endif()

add_library(libudfread STATIC
  ${CMAKE_CURRENT_SOURCE_DIR}/src/blockinput.h
  ${CMAKE_CURRENT_SOURCE_DIR}/src/default_blockinput.h
  ${CMAKE_CURRENT_SOURCE_DIR}/src/default_blockinput.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/ecma167.h
  ${CMAKE_CURRENT_SOURCE_DIR}/src/ecma167.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/udfread.h
  ${CMAKE_CURRENT_SOURCE_DIR}/src/udfread.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/udfread-version.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/udfread-version.h
)

set_target_properties(libudfread
  PROPERTIES
    COMPILE_PDB_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}
    PDB_NAME libudfread
    PDB_NAME_DEBUG libudfreadd
    COMPILE_PDB_NAME libudfread
    COMPILE_PDB_NAME_DEBUG libudfreadd
)

target_compile_definitions(libudfread
  PRIVATE
    _CRT_SECURE_NO_WARNINGS
    HAVE_FCNTL_H
)
target_link_options(libudfread
  PRIVATE
    /INCREMENTAL:NO
    /debug:full
)
if(WINDOWS_STORE)
  target_compile_definitions(libudfread
    PRIVATE
      MS_APP
  )
endif()
target_include_directories(libudfread
  PRIVATE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
  INTERFACE
  $<INSTALL_INTERFACE:include/udfread>
)

install(FILES
  ${PROJECT_BINARY_DIR}/RelWithDebInfo/libudfread.pdb
  DESTINATION lib
  CONFIGURATIONS RelWithDebInfo
)
install(FILES
  ${PROJECT_BINARY_DIR}/Debug/libudfreadd.pdb
  DESTINATION lib
  CONFIGURATIONS Debug
)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/libudfread-config-version.cmake
  VERSION ${libudfread_VERSION}
  COMPATIBILITY AnyNewerVersion
)

install(TARGETS libudfread EXPORT libudfread
  RUNTIME DESTINATION bin
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
)


install(FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/src/udfread-version.h
  ${CMAKE_CURRENT_SOURCE_DIR}/src/udfread.h
  ${CMAKE_CURRENT_SOURCE_DIR}/src/blockinput.h
  DESTINATION include/udfread
)

install(EXPORT libudfread
  FILE
    libudfread.cmake
  NAMESPACE
    libudfread::
  DESTINATION
    lib/cmake/libudfread
)
install(
  FILES
    cmake/libudfread-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/libudfread-config-version.cmake
  DESTINATION
    lib/cmake/libudfread
)
