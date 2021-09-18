/*
 *  Copyright (C) 2005-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "threads/CriticalSection.h"
#include "threads/Timer.h"
#include "windowing/WinSystem.h"
#include "threads/SystemClock.h"

#include <string>
#include <vector>

typedef struct _CGLContextObject *CGLContextObj;
typedef struct CGRect NSRect;

class IDispResource;
class CWinEventsOSX;
class CWinSystemOSXImpl;
#ifdef __OBJC__
  @class NSOpenGLContext;
  @class NSWindow;
  @class OSXGLView;
#else
  class NSWindow;
  class OSXGLView;
#endif

class CWinSystemOSX : public CWinSystemBase, public ITimerCallback
{
public:

  CWinSystemOSX();
  ~CWinSystemOSX() override;

  // ITimerCallback interface
  void OnTimeout() override;

  // CWinSystemBase
  bool InitWindowSystem() override;
  bool DestroyWindowSystem() override;
  bool CreateNewWindow(const std::string& name, bool fullScreen, RESOLUTION_INFO& res) override;
  bool DestroyWindow() override;
  bool ResizeWindow(int newWidth, int newHeight, int newLeft, int newTop) override;
  bool SetFullScreen(bool fullScreen, RESOLUTION_INFO& res, bool blankOtherDisplays) override;
  void UpdateResolutions() override;
  void NotifyAppFocusChange(bool bGaining) override;
  void ShowOSMouse(bool show) override;
  bool Minimize() override;
  bool Restore() override;
  bool Hide() override;
  bool Show(bool raise = true) override;
  void OnMove(int x, int y) override;

  void SetOcclusionState(bool occluded);

  std::string GetClipboardText() override;

  void Register(IDispResource *resource) override;
  void Unregister(IDispResource *resource) override;

  std::unique_ptr<CVideoSync> GetVideoSync(void* clock) override;

  void        WindowChangedScreen();

  void        AnnounceOnLostDevice();
  void        AnnounceOnResetDevice();
  void        HandleOnResetDevice();
  void        StartLostDeviceTimer();
  void        StopLostDeviceTimer();

  void         SetMovedToOtherScreen(bool moved) { m_movedToOtherScreen = moved; }
  int          CheckDisplayChanging(uint32_t flags);
  void         SetFullscreenWillToggle(bool toggle){ m_fullscreenWillToggle = toggle; }
  bool         GetFullscreenWillToggle(){ return m_fullscreenWillToggle; }

  CGLContextObj GetCGLContextObj();

  void GetConnectedOutputs(std::vector<std::string> *outputs);

  // winevents override
  bool MessagePump() override;

  NSRect GetWindowDimensions();

protected:
  std::unique_ptr<KODI::WINDOWING::IOSScreenSaver> GetOSScreenSaverImpl() override;

  void  HandlePossibleRefreshrateChange();
  void  GetScreenResolution(int* w, int* h, double* fps, int screenIdx);
  void  EnableVSync(bool enable);
  bool  SwitchToVideoMode(int width, int height, double refreshrate);
  void  FillInVideoModes();
  bool  FlushBuffer(void);
  bool  IsObscured(void);
  void  StartTextInput();
  void  StopTextInput();

  std::unique_ptr<CWinSystemOSXImpl> m_impl;
  static void                 *m_lastOwnedContext;
  std::string                  m_name;
  bool                         m_obscured;
  NSWindow                    *m_appWindow;
  OSXGLView                   *m_glView;
  bool                         m_movedToOtherScreen;
  int                          m_lastDisplayNr;
  double                       m_refreshRate;

  CCriticalSection             m_resourceSection;
  std::vector<IDispResource*>  m_resources;
  CTimer                       m_lostDeviceTimer;
  bool                         m_delayDispReset;
  XbmcThreads::EndTime         m_dispResetTimer;
  int m_updateGLContext = 0;
  bool                         m_fullscreenWillToggle;
  CCriticalSection             m_critSection;
};
