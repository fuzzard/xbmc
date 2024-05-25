if(TARGET OpenGL::GL)
  list(APPEND SOURCES OSXGLView.mm
                      WindowControllerMacOS.mm
                      WinSystemOSXGL.mm)
  list(APPEND HEADERS OSXGLView.h
                      WindowControllerMacOS.h
                      WinSystemOSXGL.h)

  core_add_library(windowing_osx_opengl)

  if(TARGET windowing_osx_opengl)
    set_target_properties(windowing_osx_opengl PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
  endif()

endif()
