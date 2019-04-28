/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputSettings.h"

#import "platform/darwin/tvos/XBMCController.h"
#import "platform/darwin/tvos/input/LibInputHandler.h"
#import "platform/darwin/tvos/input/LibInputRemote.h"

#import <Foundation/Foundation.h>

// Default Timer values (seconds)
const float REPEATED_KEYPRESS_DELAY_S = 0.50;
const float REPEATED_KEYPRESS_PAUSE_S = 0.05;

@implementation TVOSLibInputSettings

@synthesize useSiriRemote = m_useSiriRemote;
@synthesize remoteIdleEnabled = m_remoteIdleEnabled;
@synthesize remoteIdleTimeout = m_remoteIdleTimeout;

- (void)setRemoteIdleEnabled:(BOOL)idle
{
  if (m_remoteIdleEnabled != idle)
  {
    m_remoteIdleEnabled = idle;
    if (m_remoteIdleEnabled == YES)
      [g_xbmcController.inputHandler.inputRemote startRemoteTimer];
  }  
}

- (void)setRemoteIdleTimeout:(int)timeout
{
  m_remoteIdleTimeout = timeout;
  [g_xbmcController.inputHandler.inputRemote startRemoteTimer];
}

@end
