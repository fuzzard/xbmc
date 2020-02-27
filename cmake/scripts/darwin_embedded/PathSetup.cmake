if(CORE_PLATFORM_NAME_LC STREQUAL tvos)
  string(CONCAT BUNDLE_IDENTIFIER_DESC "${BUNDLE_IDENTIFIER_DESC}" " (app, top shelf, group ID)")
endif()
include(cmake/scripts/osx/PathSetup.cmake)
