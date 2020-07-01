/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "threads/CriticalSection.h"
#include "threads/Timer.h"
#include "windowing/WinSystem.h"
#include "rendering/gl/RenderSystemGL.h"

//#include "windowing/osx/OSXScreenManager.h"

#include <string>
#include <vector>

//#include <Cocoa/Cocoa.h>
//#import <AppKit/AppKit.h>

//typedef struct SDL_Surface SDL_Surface;

typedef struct _CGLContextObject *CGLContextObj;

class IDispResource;
class CWinEventsOSX;
class CWinSystemOSXImpl;
class COSXScreenManager;
#ifdef __OBJC__
@class NSOpenGLContext;
@class NSWindow;
#endif


struct CGPoint;
struct AppWindowWrapper;
struct GLViewWrapper;

class CWinSystemOSX : public CWinSystemBase
{
public:

  CWinSystemOSX();
  ~CWinSystemOSX() override;

  // CWinSystemBase
  bool InitWindowSystem() override;
  bool DestroyWindowSystem() override;
  bool CreateNewWindow(const std::string& name, bool fullScreen, RESOLUTION_INFO& res) override;
  bool DestroyWindow() override;
  bool ResizeWindow(int newWidth, int newHeight, int newLeft, int newTop) override;
  bool SetFullScreen(bool fullScreen, RESOLUTION_INFO& res, bool blankOtherDisplays) override;
  void NotifyAppFocusChange(bool bGaining) override;
  void ShowOSMouse(bool show) override;
  bool Minimize() override;
  bool Restore() override;
  bool Hide() override;
  bool Show(bool raise = true) override;
  void OnMove(int x, int y) override;
void FinishWindowResize(int newWidth, int newHeight) override;
     virtual int GetCurrentScreen();
    void        SetFullscreenWillToggle(bool toggle){ m_fullscreenWillToggle = toggle; }
bool        GetFullscreenWillToggle(){ return m_fullscreenWillToggle; }

  void Register(IDispResource *resource) override;
  void Unregister(IDispResource *resource) override;

  std::unique_ptr<CVideoSync> GetVideoSync(void* clock) override;

  void        WindowChangedScreen();

  void GetConnectedOutputs(std::vector<std::string> *outputs);
    
    void UpdateDesktopResolution2(RESOLUTION_INFO& newRes, const std::string &output, int width, int height, float refreshRate, uint32_t dwFlags);
    void HandleNativeMousePosition();

    void UpdateResolutions();
void SetMovedToOtherScreen(bool moved);
void HandleDelayedDisplayReset();
std::string GetClipboardText(void);
void ConvertLocationFromScreen(CGPoint *point);
void EnableTextInput(bool bEnable);
void MessagePush(XBMC_Event* newEvent);


  CGLContextObj  GetCGLContextObj();
    void EnableVSync(bool enable);
void GetScreenResolution(int* w, int* h, double* fps, int screenIdx);
    
    
    
protected:
  std::unique_ptr<KODI::WINDOWING::IOSScreenSaver> GetOSScreenSaverImpl() override;

  bool  FlushBuffer(void);
  void  StartTextInput();
  void  StopTextInput();
bool  SwitchToVideoMode(int width, int height, double refreshrate);
  std::unique_ptr<CWinSystemOSXImpl> m_impl;
  AppWindowWrapper*  m_appWindow;
  GLViewWrapper* m_glView;

  bool                         m_fullscreenWillToggle;
  int                          m_lastX;
  int                          m_lastY;

  bool                         m_movedToOtherScreen;
  int                          m_lastDisplayNr;
  double                       m_refreshRate;

  CCriticalSection m_resourceSection;
  CCriticalSection             m_critSection;
  COSXScreenManager           *m_pScreenManager;

  int m_updateGLContext = 0;
};
