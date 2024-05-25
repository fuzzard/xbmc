set(SOURCES TVOSDirectory.cpp
            TVOSFile.cpp
            TVOSFileUtils.mm)

set(HEADERS TVOSDirectory.h
            TVOSFile.h
            TVOSFileUtils.h)

core_add_library(platform_tvos_filesystem)

if(TARGET platform_tvos_filesystem)
  set_target_properties(platform_tvos_filesystem PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
