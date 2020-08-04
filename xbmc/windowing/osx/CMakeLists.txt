set(SOURCES CocoaDPMSSupport.cpp
            OSScreenSaverOSX.cpp
            WinEventsOSX.mm
            WinSystemOSX.mm
            WinSystemOSXGL.mm
            VideoSyncOsx.mm)
set(HEADERS CocoaDPMSSupport.h
            OSScreenSaverOSX.h
            WinEventsOSX.h
            WinSystemOSX.h
            WinSystemOSXGL.h
            VideoSyncOsx.h)

core_add_library(windowing_osx)
