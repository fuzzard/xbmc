set(SOURCES NetworkIOS.mm)

set(HEADERS NetworkIOS.h
            route.h)

core_add_library(platform_ios_network)

if(TARGET platform_ios_network)
  set_target_properties(platform_ios_network PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
