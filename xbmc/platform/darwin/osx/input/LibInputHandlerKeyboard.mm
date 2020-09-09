/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputHandlerKeyboard.h"

#include "AppInboundProtocol.h"
#include "ServiceBroker.h"
#include "windowing/XBMC_events.h"

@implementation OSXLibInputHandlerKeyboard

#pragma mark - internal key press methods

//! @Todo: factor out siriremote customcontroller to a setting?
// allow to select multiple customcontrollers via setting list?
- (void)sendButtonPressed:(NSEvent *)theEvent
{
        XBMC_Event newEvent;
        newEvent.type = XBMC_KEYDOWN;
//        newEvent.key.keysym.scancode = theEvent.key.keysym.scancode;
//        newEvent.key.keysym.sym = (XBMCKey) theEvent.key.keysym.sym;
//        newEvent.key.keysym.unicode = theEvent.key.keysym.unicode;

        // Check if the Windows keys are down because SDL doesn't flag this.
//        uint16_t mod = theEvent.key.keysym.mod;
//        uint8_t* keystate = SDL_GetKeyState(NULL);
//        if (keystate[SDLK_LSUPER] || keystate[SDLK_RSUPER])
//          mod |= XBMCKMOD_LSUPER;
//        newEvent.key.keysym.mod = (XBMCMod) mod;

        // don't handle any more messages in the queue until we've handled keydown,
        // if a keyup is in the queue it will reset the keypress before it is handled.
        std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
        if (appPort)
          appPort->OnEvent(newEvent);
}

- (void)sendButtonReleased:(NSEvent *)theEvent
{

}

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  return self;
}

@end
