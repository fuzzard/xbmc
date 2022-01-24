include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

if(ENABLE_GPLV3_DEPENDS)
  set(MODULE_LC libcdio-gplv3)
else()
  set(MODULE_LC libcdio)
endif()

SETUP_BUILD_VARS()

# Force cache so anything with a dependency on this can just use find_package
set(CDIO_LIBRARY ${DEPENDS_PATH}/lib/libcdio.a CACHE INTERNAL "" FORCE)
set(CDIO_INCLUDE_DIR ${DEPENDS_PATH}/include CACHE INTERNAL "" FORCE)
set(CDIO_VERSION ${${MODULE}_VERSION} CACHE INTERNAL "" FORCE)

if(ENABLE_GPLV3_DEPENDS)
  set(CMD_PATCH PATCH_COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/01-fix-glob-on-android.patch
                      COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/osx.patch
                )
else()
  set(CONFIGURE_OPTS --with-cd-paranoia=no)
  set(CMD_PATCH PATCH_COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/configure.patch
                      COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/cross.patch
                )
endif()

# Set Target Configure command
set(CMD_CONFIGURE CONFIGURE_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${SETBUILDENV} autoreconf -vif
                            COMMAND ${SETBUILDENV}
                                    ./configure
                                    --host=${HOST}
                                    --prefix=${DEPENDS_PATH}
                                    --with-cd-drive=no
                                    --with-cd-info=no
                                    --with-cdda-player=no
                                    --with-cd-read=no
                                    --with-iso-info=no
                                    --with-iso-read=no
                                    --disable-example-progs
                                    --disable-cpp-progs
                                    --enable-cxx
                                    --disable-shared
                                    ${CONFIGURE_OPTS}
                  )

# Set Target Build command
set(CMD_BUILD BUILD_COMMAND $(MAKE) -C <SOURCE_DIR>/lib)

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND $(MAKE) -C <SOURCE_DIR>/lib install
                        COMMAND $(MAKE) -C <SOURCE_DIR>/include install
                        COMMAND $(MAKE) install-data-am
                )

# Set Target Byproduct
set(BYPRODUCT BUILD_BYPRODUCTS ${CDIO_LIBRARY})

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

# Postbuild custom command
if(NOT ENABLE_GPLV3_DEPENDS)
  add_custom_command(TARGET ${MODULE_LC}
                     POST_BUILD
                     COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/include/cdio/cdtext.h ${DEPENDS_PATH}/include/cdio/
                     )
endif()
