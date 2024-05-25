set(SOURCES TVOSPowerSyscall.cpp)

set(HEADERS TVOSPowerSyscall.h)

core_add_library(platform_tvos_powermanagement)

if(TARGET platform_tvos_powermanagement)
  set_target_properties(platform_tvos_powermanagement PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
