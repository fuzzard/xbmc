set(BUNDLE_IDENTIFIER_DESC "Bundle ID")
if(CORE_PLATFORM_NAME_LC STREQUAL tvos)
  string(CONCAT BUNDLE_IDENTIFIER_DESC "${BUNDLE_IDENTIFIER_DESC}" " (app, top shelf, group ID)")
endif()
set(PLATFORM_BUNDLE_IDENTIFIER "${APP_PACKAGE}-${CORE_PLATFORM_NAME_LC}" CACHE STRING "${BUNDLE_IDENTIFIER_DESC}")
list(APPEND final_message "Bundle ID: ${PLATFORM_BUNDLE_IDENTIFIER}")
include(cmake/scripts/osx/PathSetup.cmake)
