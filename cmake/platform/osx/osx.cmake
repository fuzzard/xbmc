if(NOT APP_RENDER_SYSTEM OR APP_RENDER_SYSTEM STREQUAL "gl")
  list(APPEND PLATFORM_REQUIRED_DEPS OpenGl)
  set(APP_RENDER_SYSTEM gl)
  list(APPEND SYSTEM_DEFINES -DGL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED)
else()
  message(SEND_ERROR "Currently only OpenGL rendering is supported. Please set APP_RENDER_SYSTEM to \"gl\"")
endif()

if(NOT APP_WINDOW_SYSTEM OR APP_WINDOW_SYSTEM STREQUAL sdl)
  list(APPEND SYSTEM_DEFINES -DHAS_SDL)
  list(APPEND PLATFORM_REQUIRED_DEPS Sdl)

  list(APPEND CORE_MAIN_SOURCE ${CMAKE_SOURCE_DIR}/xbmc/platform/darwin/osx/SDLMain.mm
                               ${CMAKE_SOURCE_DIR}/xbmc/platform/darwin/osx/SDLMain.h)
else()
  message(SEND_ERROR "Currently only SDL windowing is supported. Please set APP_WINDOW_SYSTEM to \"sdl\"")
endif()
