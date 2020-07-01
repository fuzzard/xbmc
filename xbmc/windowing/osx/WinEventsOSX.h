/*
 *  Copyright (C) 2011-2018 Team Kodi
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

class CWinEventsOSX : public IWinEvents, public CThread
{
public:
  CWinEventsOSX();
  ~CWinEventsOSX();

  void MessagePush(XBMC_Event* newEvent);
  size_t GetQueueSize();

  bool MessagePump();

private:
  bool ProcessOSXShortcuts(XBMC_Event& event);

  CCriticalSection m_eventsCond;
  std::list<XBMC_Event> m_events;
};
