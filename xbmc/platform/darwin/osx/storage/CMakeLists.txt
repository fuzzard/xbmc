set(SOURCES OSXStorageProvider.cpp)

set(HEADERS OSXStorageProvider.h)

core_add_library(platform_osx_storage)

if(TARGET platform_osx_storage)
  set_target_properties(platform_osx_storage PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
