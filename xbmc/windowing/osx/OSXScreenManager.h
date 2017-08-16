#pragma once

/*
 *      Copyright (C) 2017 Team Kodi
 *      http://kodi.tv
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
 *  along with Kodi; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */


#include "threads/CriticalSection.h"
#include "threads/Timer.h"

class IDispResource;
class CWinSystemOSX;
@class NSWindow;

#define MAX_DISPLAYS 32

class COSXScreenManager : public ITimerCallback
{
public:
  
  COSXScreenManager();
  virtual ~COSXScreenManager();
  
  virtual void Init(CWinSystemOSX *windowing);
  virtual void Deinit();
  
  virtual void RegisterWindow(NSWindow *appWindow);
  
  // ITimerCallback interface
  virtual void OnTimeout() override;
  
  // IDispResource register/unregister methods
  virtual void Register(IDispResource *resource);
  virtual void Unregister(IDispResource *resource);

  // handlers related to runtime changes to screens
  void        AnnounceOnLostDevice();
  void        AnnounceOnResetDevice();
  void        HandleOnResetDevice();
  void        StartLostDeviceTimer();
  void        StopLostDeviceTimer();
  
  virtual int GetNumScreens();
  virtual int GetCurrentScreen();
  virtual void UpdateResolutions();
  
  void  SetMovedToOtherScreen(bool moved);

  
  void  WindowChangedScreen();

  int   CheckDisplayChanging(uint32_t flags);

  void  GetScreenResolution(int* w, int* h, double* fps, int screenIdx);
  void  EnableVSync(bool enable);
  void  HandleDelayedDisplayReset();
  // returns true if the display nummer differs from the last display number
  bool  SetLastDisplayNr(int lastDisplayNr);
  bool  SwitchToVideoMode(int width, int height, double refreshrate, int screenIdx);
  
  void BlankOtherDisplays(int screen_index);
  void UnblankDisplays(void);


  
protected:
  
  void  HandlePossibleRefreshrateChange();
  void  FillInVideoModes();
  
  CCriticalSection             m_resourceSection;
  std::vector<IDispResource*>  m_resources;
  CTimer                       m_lostDeviceTimer;
  XbmcThreads::EndTime         m_dispResetTimer;
  CWinSystemOSX               *m_pWindowing;

  double                       m_refreshRate;
  bool                         m_delayDispReset;
  bool                         m_movedToOtherScreen;
  int                          m_lastDisplayNr;
  NSWindow                    *m_pAppWindow;
  NSWindow                    *m_blankingWindows[MAX_DISPLAYS];

};
