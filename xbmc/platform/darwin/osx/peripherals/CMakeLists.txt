set(SOURCES PeripheralBusUSB.cpp)

set(HEADERS PeripheralBusUSB.h)

core_add_library(platform_darwin_osx_peripherals)

if(TARGET platform_darwin_osx_peripherals)
  set_target_properties(platform_darwin_osx_peripherals PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
