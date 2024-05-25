set(SOURCES CocoaDPMSSupport.cpp
            OSScreenSaverOSX.cpp
            VideoSyncOsx.mm
            WinEventsOSX.mm
            WinEventsOSXImpl.mm
            WinSystemOSX.mm)
set(HEADERS CocoaDPMSSupport.h
            OSScreenSaverOSX.h
            WinEventsOSX.h
            WinEventsOSXImpl.h
            VideoSyncOsx.h
            WinSystemOSX.h)

core_add_library(windowing_osx)

if(TARGET windowing_osx)
  set_target_properties(windowing_osx PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
