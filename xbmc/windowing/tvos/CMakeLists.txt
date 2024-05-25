set(SOURCES OSScreenSaverTVOS.mm
            WinEventsTVOS.mm
            WinSystemTVOS.mm
            VideoSyncTVos.cpp)
set(HEADERS OSScreenSaverTVOS.h
            WinEventsTVOS.h
            WinSystemTVOS.h
            VideoSyncTVos.h)

core_add_library(windowing_tvos)

if(TARGET windowing_tvos)
  set_target_properties(windowing_tvos PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
