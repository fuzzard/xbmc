#pragma once

/*
 *      Copyright (C) 2005-2013 Team XBMC
 *      http://xbmc.org
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with XBMC; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */

#include "windowing/WinSystem.h"
#include "threads/CriticalSection.h"

typedef struct _CGLContextObject *CGLContextObj;
class COSXScreenManager;
class IDispResource;
struct CGPoint;

class CWinSystemOSX : public CWinSystemBase
{
public:

  CWinSystemOSX();
  virtual ~CWinSystemOSX();

  // methods forwarded to m_pScreenManager
  virtual int GetNumScreens() override;
  virtual int GetCurrentScreen() override;
  void EnableVSync(bool enable);
  void HandleDelayedDisplayReset();
  void Register(IDispResource *resource);
  void Unregister(IDispResource *resource);
  void SetMovedToOtherScreen(bool moved);
  virtual void UpdateResolutions() override;
  // make the base implementation accessible from COSXScreenManager
  void UpdateDesktopResolution(RESOLUTION_INFO& newRes, int screen, int width, int height, float refreshRate, uint32_t dwFlags = 0);
  
  // CWinSystemBase
  virtual bool InitWindowSystem() override;
  virtual bool DestroyWindowSystem() override;
  virtual bool CreateNewWindow(const std::string& name, bool fullScreen, RESOLUTION_INFO& res) override;
  virtual bool DestroyWindow() override;
  virtual bool ResizeWindow(int newWidth, int newHeight, int newLeft, int newTop) override;
  virtual bool SetFullScreen(bool fullScreen, RESOLUTION_INFO& res, bool blankOtherDisplays) override;
  virtual void NotifyAppFocusChange(bool bGaining) override;
  virtual void ShowOSMouse(bool show) override;
  virtual bool Minimize() override;
  virtual bool Restore() override;
  virtual bool Hide() override;
  virtual bool Show(bool raise = true) override;
  virtual void OnMove(int x, int y) override;
  virtual std::unique_ptr<CVideoSync> GetVideoSync(void *clock) override;

  virtual void EnableTextInput(bool bEnable) override;
  virtual bool IsTextInputEnabled() override;

  void        SetFullscreenWillToggle(bool toggle){ m_fullscreenWillToggle = toggle; }
  bool        GetFullscreenWillToggle(){ return m_fullscreenWillToggle; }
  
  CGLContextObj  GetCGLContextObj();
  
  virtual std::string  GetClipboardText(void) override;
  void ConvertLocationFromScreen(CGPoint *point);

  
protected:
  virtual std::unique_ptr<KODI::WINDOWING::IOSScreenSaver> GetOSScreenSaverImpl() override;
  void  HandleNativeMousePosition();
  bool  FlushBuffer(void);
  void  StartTextInput();
  void  StopTextInput();

  void                        *m_appWindow;
  void                        *m_glView;

  bool                         m_fullscreenWillToggle;
  int                          m_lastX;
  int                          m_lastY;

  CCriticalSection             m_critSection;
  COSXScreenManager           *m_pScreenManager;
};
