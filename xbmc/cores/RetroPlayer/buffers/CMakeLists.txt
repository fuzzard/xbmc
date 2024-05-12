set(SOURCES BaseRenderBuffer.cpp
            BaseRenderBufferPool.cpp
            RenderBufferManager.cpp
)

set(HEADERS BaseRenderBuffer.h
            BaseRenderBufferPool.h
            IRenderBuffer.h
            IRenderBufferPool.h
            RenderBufferManager.h
)

if(TARGET kodi::Gl OR TARGET kodi::OpenGLES)
  list(APPEND SOURCES RenderBufferOpenGLES.cpp
                      RenderBufferPoolOpenGLES.cpp)
  list(APPEND HEADERS RenderBufferOpenGLES.h
                      RenderBufferPoolOpenGLES.h)
endif()

if(TARGET kodi::OpenGl)
  list(APPEND SOURCES RenderBufferOpenGL.cpp
                      RenderBufferPoolOpenGL.cpp)
  list(APPEND HEADERS RenderBufferOpenGL.h
                      RenderBufferPoolOpenGL.h)
endif()

if(("gbm" IN_LIST CORE_PLATFORM_NAME_LC OR "wayland" IN_LIST CORE_PLATFORM_NAME_LC) AND TARGET kodi::EGL)
  list(APPEND SOURCES RenderBufferDMA.cpp
                      RenderBufferPoolDMA.cpp)
  list(APPEND HEADERS RenderBufferDMA.h
                      RenderBufferPoolDMA.h)
endif()

core_add_library(rp-buffers)
