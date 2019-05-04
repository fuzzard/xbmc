set(SOURCES
			MainController.mm
			MainEAGLView.mm
			TVOSSettingsHandler.mm
			tvosShared.m
			TVOSTopShelf.mm)

set(HEADERS
			MainApplication.h
			MainController.h
			MainEAGLView.h
			TVOSSettingsHandler.h
			tvosShared.h
			TVOSTopShelf.h)

core_add_library(platform_tvos)
