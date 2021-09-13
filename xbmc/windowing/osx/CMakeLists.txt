set(SOURCES CocoaDPMSSupport.cpp
            OSScreenSaverOSX.cpp
            VideoSyncOsx.mm)
set(HEADERS CocoaDPMSSupport.h
            OSScreenSaverOSX.h
            VideoSyncOsx.h)

if(SDL_FOUND)
  list(APPEND SOURCES WinEventsSDL.cpp
                      WinSystemOSXSDL.mm)
  list(APPEND HEADERS WinEventsSDL.h
                      WinSystemOSXSDL.h)
else()
  list(APPEND SOURCES WinEventsOSX.mm
                      WinEventsOSXImpl.mm
                      WinSystemOSX.mm)
  list(APPEND HEADERS WinEventsOSX.h
                      WinEventsOSXImpl.h
                      WinSystemOSX.h)
endif()

if(OPENGL_FOUND)
  list(APPEND SOURCES WinSystemOSXGL.mm)
  list(APPEND HEADERS WinSystemOSXGL.h)
endif()

core_add_library(windowing_osx)
