if(ENABLE_INTERNAL_CROSSGUID)
  if(NOT CROSSGUID_FOUND)
    include(cmake/modules/depends/target/BuildCrossGUID.cmake)
  endif()
else()
  find_path(CROSSGUID_INCLUDE_DIR NAMES guid.hpp guid.h)

  find_library(CROSSGUID_LIBRARY_RELEASE NAMES crossguid)
  find_library(CROSSGUID_LIBRARY_DEBUG NAMES crossguidd)

  include(SelectLibraryConfigurations)
  select_library_configurations(CROSSGUID)
  add_custom_target(crossguid)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CrossGUID
                                  REQUIRED_VARS CROSSGUID_LIBRARY CROSSGUID_INCLUDE_DIR)

if(CROSSGUID_FOUND)
  set(CROSSGUID_LIBRARIES ${CROSSGUID_LIBRARY})
  set(CROSSGUID_INCLUDE_DIRS ${CROSSGUID_INCLUDE_DIR})
  set(CROSSGUID_FOUND TRUE CACHE INTERNAL "" FORCE)

  if(EXISTS "${CROSSGUID_INCLUDE_DIR}/guid.hpp")
    set(CROSSGUID_DEFINITIONS -DHAVE_NEW_CROSSGUID)
  endif()

  set_target_properties(crossguid PROPERTIES FOLDER "External Projects")
endif()

if(NOT WIN32 AND NOT APPLE)
  find_package(UUID REQUIRED)
  list(APPEND CROSSGUID_INCLUDE_DIRS ${UUID_INCLUDE_DIRS})
  list(APPEND CROSSGUID_LIBRARIES ${UUID_LIBRARIES})
endif()

mark_as_advanced(CROSSGUID_INCLUDE_DIR CROSSGUID_LIBRARY)
