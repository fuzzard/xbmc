set(SOURCES WinEventsIOS.mm
            WinSystemIOS.mm
            VideoSyncIos.cpp)
set(HEADERS WinEventsIOS.h
            WinSystemIOS.h
            VideoSyncIos.h)

core_add_library(windowing_ios)

if(TARGET windowing_ios)
  set_target_properties(windowing_ios PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
