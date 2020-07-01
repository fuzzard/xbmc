/*
 *  Copyright (C) 2011-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "WinEventsOSX.h"

#include "AppInboundProtocol.h"
#include "ServiceBroker.h"
#include "guilib/GUIWindowManager.h"
#include "input/InputManager.h"
#include "input/XBMC_vkeys.h"
#include "threads/CriticalSection.h"
#include "utils/log.h"

#include <list>

static CCriticalSection g_inputCond;

static std::list<XBMC_Event> events;

CWinEventsOSX::CWinEventsOSX() : CThread("CWinEventsOSX")
{
  CLog::Log(LOGDEBUG, "CWinEventsOSX::CWinEventsOSX");
  Create();
}

CWinEventsOSX::~CWinEventsOSX()
{
  m_bStop = true;
  StopThread(true);
}

void CWinEventsOSX::MessagePush(XBMC_Event* newEvent)
{
  CSingleLock lock(m_eventsCond);

  m_events.push_back(*newEvent);
}

size_t CWinEventsOSX::GetQueueSize()
{
  CSingleLock lock(g_inputCond);
  return events.size();
}


bool CWinEventsOSX::MessagePump()
{
  bool ret = false;
  std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();

  // Do not always loop, only pump the initial queued count events. else if ui keep pushing
  // events the loop won't finish then it will block xbmc main message loop.
  for (size_t pumpEventCount = GetQueueSize(); pumpEventCount > 0; --pumpEventCount)
  {
    // Pop up only one event per time since in App::OnEvent it may init modal dialog which init
    // deeper message loop and call the deeper MessagePump from there.
    XBMC_Event pumpEvent;
    {
      CSingleLock lock(g_inputCond);
      if (events.empty())
        return ret;
      pumpEvent = events.front();
      events.pop_front();
    }

    if (appPort)
      ret = appPort->OnEvent(pumpEvent);
  }
  return ret;
}

bool CWinEventsOSX::ProcessOSXShortcuts(XBMC_Event& event)
{
/*
  bool cmd = !!(event.key.keysym.mod & (XBMCKMOD_LMETA | XBMCKMOD_RMETA));
  if (cmd && event.type == XBMC_KEYDOWN)
  {
    switch(event.key.keysym.sym)
    {
      case XBMCK_q:  // CMD-q to quit
        if (!g_application.m_bStop)
        {
          XBMC_Event newEvent;
          memset(&newEvent, 0, sizeof(newEvent));
          newEvent.type = XBMC_QUIT;
          CWinEvents::MessagePush(&newEvent);
        }
        return true;

      case XBMCK_f: // CMD-f to toggle fullscreen
      {
        KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_TOGGLEFULLSCREEN);
        return true;
      }
      case XBMCK_s: // CMD-s to take a screenshot
      {
        CAction *action = new CAction(ACTION_TAKE_SCREENSHOT);
        KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_GUI_ACTION, WINDOW_INVALID, -1, static_cast<void*>(action));
        return true;
      }
      case XBMCK_h: // CMD-h to hide (but we minimize for now)
      case XBMCK_m: // CMD-m to minimize
      {
        XBMC_Event newEvent;
        memset(&newEvent, 0, sizeof(newEvent));
        newEvent.type = XBMC_MINIMIZE;
        CWinEvents::MessagePush(&newEvent);
        return true;
      }
      case XBMCK_v: // CMD-v to paste clipboard text
        if (g_Windowing.IsTextInputEnabled())
        {
          const char *szStr = Cocoa_Paste();
          if (szStr)
          {
            CGUIMessage msg(ACTION_INPUT_TEXT, 0, 0);
            msg.SetLabel(szStr);
//            CServiceBroker::GetGUI()->GetWindowManager().SendMessage(msg, g_windowManager.GetFocusedWindow());
          }
        }
        return true;

      default:
        return false;
    }
  }
*/
 return false;
}
