/*
 *  Copyright (C) 2012-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "threads/CriticalSection.h"
#include "threads/Event.h"
#include "threads/Thread.h"
#include "windowing/WinEvents.h"

#include <list>
#include <queue>
#include <string>
#include <vector>

class CWinEventsOSX : public IWinEvents, public CThread
{
public:
  CWinEventsOSX();
  ~CWinEventsOSX();

  void MessagePush(XBMC_Event* newEvent);
  size_t GetQueueSize();

  bool MessagePump();

private:
  CCriticalSection m_eventsCond;
  std::list<XBMC_Event> m_events;
};


/*class CWinEventsOSXImp: public IRunnable
{
public:
  CWinEventsOSXImp();
  virtual ~CWinEventsOSXImp();
  static void MessagePush(XBMC_Event *newEvent);
  static bool MessagePump();
  static size_t GetQueueSize();

  static void EnableInput();
  static void DisableInput();
  static void HandleInputEvent(void *event);

  void *GetEventTap(){return mEventTap;}
  bool TapVolumeKeys(){return mTapVolumeKeys;}
  bool TapPowerKey(){return mTapPowerKey;}
  void SetHotKeysEnabled(bool enable){mHotKeysEnabled = enable;}
  bool AreHotKeysEnabled(){return mHotKeysEnabled;}

  virtual void Run();

private:
  static CWinEventsOSXImp *WinEvents;

  void *mRunLoopSource;
  void *mRunLoop;
  void *mEventTap;
  void *mLocalMonitorId;
  bool mHotKeysEnabled;
  bool mTapVolumeKeys;
  bool mTapPowerKey;
  CThread *m_TapThread;

  void enableHotKeyTap();
  void disableHotKeyTap();
  void enableInputEvents();
  void disableInputEvents();
};
*/
