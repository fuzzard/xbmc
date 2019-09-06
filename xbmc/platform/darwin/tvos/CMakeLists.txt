set(SOURCES PreflightHandler.mm
            TVOSEAGLView.mm
            TVOSSettingsHandler.mm
            tvosShared.m
            TVOSTopShelf.mm
            XBMCController.mm)

set(HEADERS PreflightHandler.h
            TVOSEAGLView.h
            TVOSSettingsHandler.h
            tvosShared.h
            TVOSTopShelf.h
            XBMCApplication.h
            XBMCController.h)

core_add_library(platform_tvos)
