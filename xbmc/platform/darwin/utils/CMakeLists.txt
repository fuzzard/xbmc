set(SOURCES DarwinInterfaceForCLog.mm)

set(HEADERS DarwinInterfaceForCLog.h)

core_add_library(platform_darwin_utils)

if(TARGET platform_darwin_utils)
  set_target_properties(platform_darwin_utils PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
