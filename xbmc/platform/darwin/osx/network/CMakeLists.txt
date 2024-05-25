set(SOURCES NetworkMacOS.mm)
set(HEADERS NetworkMacOS.h)

core_add_library(platform_macos_network)

if(TARGET platform_macos_network)
  set_target_properties(platform_macos_network PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
