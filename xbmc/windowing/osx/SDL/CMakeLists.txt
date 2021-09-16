if(SDL_FOUND)
  list(APPEND SOURCES WinEventsSDL.cpp
                      WinSystemOSXSDL.mm)
  list(APPEND HEADERS WinEventsSDL.h
                      WinSystemOSXSDL.h)

  core_add_library(windowing_osx_SDL)
endif()
