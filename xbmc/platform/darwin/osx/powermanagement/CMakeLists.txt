set(SOURCES CocoaPowerSyscall.cpp)
set(HEADERS CocoaPowerSyscall.h)

core_add_library(platform_darwin_osx_powermanagement)

if(TARGET platform_darwin_osx_powermanagement)
  set_target_properties(platform_darwin_osx_powermanagement PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
