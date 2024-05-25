set(SOURCES ZeroconfBrowserDarwin.cpp
            ZeroconfDarwin.cpp)

set(HEADERS ZeroconfBrowserDarwin.h
            ZeroconfDarwin.h)

core_add_library(platform_darwin_network)

if(TARGET platform_darwin_network)
  set_target_properties(platform_darwin_network PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
