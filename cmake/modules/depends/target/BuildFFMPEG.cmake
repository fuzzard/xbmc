include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE ffmpeg)

# Cant use SETUP_BUILD_VARS() macro due to github BASE_URL
get_archive_name(${MODULE})
string(TOUPPER ${MODULE} MODULE)

# allow user to override the download URL with a local tarball
# needed for offline build envs
if(${MODULE}_URL)
  get_filename_component(${MODULE}_URL "${${MODULE}_URL}" ABSOLUTE)
else()
  # github tarball format is tagname.tar.gz (eg 4.4-N-Alpha1.tar.gz)
  # tagname is our ${MODULE}_VER from VERSION file.
  set(${MODULE}_URL ${${MODULE}_BASE_URL}/archive/${${MODULE}_VER}.tar.gz)
endif()
if(VERBOSE)
  message(STATUS "${MODULE}_URL: ${${MODULE}_URL}")
endif()

if (NOT DAV1D_FOUND)
  message(STATUS "dav1d not found, internal ffmpeg build will be missing AV1 support!")
endif()

set(FFMPEG_OPTIONS -DENABLE_CCACHE=${ENABLE_CCACHE}
                   -DCCACHE_PROGRAM=${CCACHE_PROGRAM}
                   -DENABLE_VAAPI=${ENABLE_VAAPI}
                   -DENABLE_VDPAU=${ENABLE_VDPAU}
                   -DENABLE_DAV1D=${DAV1D_FOUND}
                   -DEXTRA_FLAGS=${FFMPEG_EXTRA_FLAGS})

if(KODI_DEPENDSBUILD)
  set(CROSS_ARGS -DDEPENDS_PATH=${DEPENDS_PATH}
                 -DPKG_CONFIG_EXECUTABLE=${PKG_CONFIG_EXECUTABLE}
                 -DCROSSCOMPILING=${CMAKE_CROSSCOMPILING}
                 -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
                 -DOS=${OS}
                 -DCMAKE_AR=${CMAKE_AR})
endif()
set(LINKER_FLAGS ${CMAKE_EXE_LINKER_FLAGS})
list(APPEND LINKER_FLAGS ${SYSTEM_LDFLAGS})

externalproject_add(ffmpeg
                    URL ${${MODULE}_URL}
                    DOWNLOAD_NAME ${${MODULE}_ARCHIVE}
                    DOWNLOAD_DIR ${TARBALL_DIR}
                    PREFIX ${CORE_BUILD_DIR}/ffmpeg
                    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                               -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                               -DFFMPEG_VER=${FFMPEG_VER}
                               -DCORE_SYSTEM_NAME=${CORE_SYSTEM_NAME}
                               -DCORE_PLATFORM_NAME=${CORE_PLATFORM_NAME_LC}
                               -DCPU=${CPU}
                               -DENABLE_NEON=${ENABLE_NEON}
                               -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                               -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                               -DENABLE_CCACHE=${ENABLE_CCACHE}
                               -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
                               -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
                               -DCMAKE_EXE_LINKER_FLAGS=${LINKER_FLAGS}
                               ${CROSS_ARGS}
                               ${FFMPEG_OPTIONS}
                               -DPKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig
                    PATCH_COMMAND ${CMAKE_COMMAND} -E copy
                                  ${CMAKE_SOURCE_DIR}/tools/depends/target/ffmpeg/CMakeLists.txt
                                  <SOURCE_DIR> &&
                                  ${CMAKE_COMMAND} -E copy
                                  ${CMAKE_SOURCE_DIR}/tools/depends/target/ffmpeg/FindGnuTls.cmake
                                  <SOURCE_DIR>)

if (ENABLE_INTERNAL_DAV1D)
  add_dependencies(ffmpeg dav1d)
endif()

find_program(BASH_COMMAND bash)
if(NOT BASH_COMMAND)
  message(FATAL_ERROR "Internal FFmpeg requires bash.")
endif()
file(WRITE ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/ffmpeg/ffmpeg-link-wrapper
"#!${BASH_COMMAND}
if [[ $@ == *${APP_NAME_LC}.bin* || $@ == *${APP_NAME_LC}${APP_BINARY_SUFFIX}* || $@ == *${APP_NAME_LC}.so* || $@ == *${APP_NAME_LC}-test* ]]
then
avformat=`PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --libs --static libavcodec`
avcodec=`PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --libs --static libavformat`
avfilter=`PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --libs --static libavfilter`
avutil=`PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --libs --static libavutil`
swscale=`PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --libs --static libswscale`
swresample=`PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/pkgconfig ${PKG_CONFIG_EXECUTABLE} --libs --static libswresample`
gnutls=`PKG_CONFIG_PATH=${DEPENDS_PATH}/lib/pkgconfig/ ${PKG_CONFIG_EXECUTABLE}  --libs-only-l --static --silence-errors gnutls`
$@ $avcodec $avformat $avcodec $avfilter $swscale $swresample -lpostproc $gnutls
else
$@
fi")
file(COPY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/ffmpeg/ffmpeg-link-wrapper
     DESTINATION ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
     FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
set(FFMPEG_LINK_EXECUTABLE "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/ffmpeg-link-wrapper <CMAKE_CXX_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" PARENT_SCOPE)
set(FFMPEG_CREATE_SHARED_LIBRARY "${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/ffmpeg-link-wrapper <CMAKE_CXX_COMPILER> <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>" PARENT_SCOPE)
set(FFMPEG_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/include)
list(APPEND FFMPEG_DEFINITIONS -DFFMPEG_VER_SHA=\"${FFMPEG_VER}\"
                               -DUSE_STATIC_FFMPEG=1)
set(FFMPEG_FOUND 1)
set_target_properties(ffmpeg PROPERTIES FOLDER "External Projects")
