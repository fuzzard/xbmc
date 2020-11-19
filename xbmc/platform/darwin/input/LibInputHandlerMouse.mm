/*
 *  Copyright (C) 2020- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputHandlerMouse.h"

#include "AppInboundProtocol.h"
#include "ServiceBroker.h"
#include "input/mouse/MouseStat.h"
#include "threads/CriticalSection.h"
#include "threads/SingleLock.h"
#include "utils/log.h"
#include "windowing/XBMC_events.h"

#import <Foundation/Foundation.h>
#import <GameController/GCController.h>

// max 4 mice connected
#define MAX_MOUSE 4

struct GCMouseState
{
  GCMouse* mouse;
  int auxButtonCount;
  int x;
  int y;
};

@implementation DarwinLibInputHandlerMouse
{
  NSMutableArray* mouseArray;
  // State for each mouse
  struct GCMouseState mouseStateStruct[MAX_MOUSE];
  CCriticalSection m_GCMutex;
  CCriticalSection m_deviceMutex;
}

- (void)addModeSwitchObserver
{
  if (@available(iOS 14.0, tvOS 14.0, macOS 11.0, *))
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mouseWasConnected:)
                                                 name:GCMouseDidConnectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mouseWasDisconnected:)
                                                 name:GCMouseDidDisconnectNotification
                                               object:nil];
  }
}

- (void)removeModeSwitchObserver
{
  if (@available(iOS 14.0, tvOS 14.0, macOS 11.0, *))
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GCMouseDidConnectNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GCMouseDidDisconnectNotification
                                                  object:nil];
  }
}

- (void)mouseWasConnected:(NSNotification*)notification
{
  GCMouse* mouse = (GCMouse*)notification.object;

  [self mouseConnection:mouse];
}

- (void)mouseWasDisconnected:(NSNotification*)notification
{
  // Lock so add/remove events are serialised
  CSingleLock lock(m_deviceMutex);
  // a mouse was disconnected
  GCMouse* mouse = (GCMouse*)notification.object;
  if (!mouseArray)
    return;

  CLog::Log(LOGINFO, "OSXLibInputHandlerMouse: mouse disconnected");

  auto i = [mouseArray indexOfObject:mouse];

  if (i == NSNotFound)
  {
    CLog::Log(LOGWARNING, "OSXLibInputHandlerMouse: failed to remove mouse. Not Found ");
    return;
  }

  for (int i = 0; i < MAX_MOUSE; i++)
  {
    if (mouseStateStruct[i].mouse == mouse)
    {
      mouseStateStruct[i].mouse = nil;
      mouseStateStruct[i].auxButtonCount = 0;
      mouseStateStruct[i].x = 0;
      mouseStateStruct[i].y = 0;
    }
  }

  CLog::Log(LOGINFO, "OSXLibInputHandlerMouse: mouse removed");

  [mouseArray removeObjectAtIndex:i];
}

- (void)mouseConnection:(GCMouse*)mouse
{
  // Lock so add/remove events are serialised
  CSingleLock lock(m_deviceMutex);

  CLog::Log(LOGDEBUG, "OSXLibInputHandlerMouse: mouse connected");

  [mouseArray addObject:mouse];

  for (int i = 0; i < MAX_MOUSE; i++)
  {
    if (mouseStateStruct[i].mouse == nil)
    {
      mouseStateStruct[i].mouse = mouse;
      mouseStateStruct[i].x = 0;
      mouseStateStruct[i].y = 0;
      [self registerChangeHandler:mouse];
      break;
    }
  }
}

- (void)registerChangeHandler:(GCMouse*)mouse
{
  mouse.mouseInput.leftButton.pressedChangedHandler =
      ^(GCControllerButtonInput* button, float value, BOOL pressed) {
        [self mouseButtonChangeHandler:mouse button:XBMC_BUTTON_LEFT state:pressed];
      };
  mouse.mouseInput.middleButton.pressedChangedHandler =
      ^(GCControllerButtonInput* button, float value, BOOL pressed) {
        [self mouseButtonChangeHandler:mouse button:XBMC_BUTTON_MIDDLE state:pressed];
      };
  mouse.mouseInput.rightButton.pressedChangedHandler =
      ^(GCControllerButtonInput* button, float value, BOOL pressed) {
        [self mouseButtonChangeHandler:mouse button:XBMC_BUTTON_RIGHT state:pressed];
      };

  mouse.mouseInput.scroll.yAxis.valueChangedHandler = ^(GCControllerAxisInput* axis, float value) {
    [self wheelChangeHandler:mouse value:value];
  };

  auto mouseState = [self getMouseState:mouse];
  if (mouseState == nil)
    return;

  int aux_button = XBMC_BUTTON_X1;
  for (GCControllerButtonInput* button in mouse.mouseInput.auxiliaryButtons)
  {
    // MOUSE_MAX_BUTTON doesnt map to XBMC_BUTTON_XX directly
    // +2 compensates for the wheelup/down defines in the middle
    if (aux_button <= (MOUSE_MAX_BUTTON + 2))
    {
      button.pressedChangedHandler = ^(GCControllerButtonInput* button, float value, BOOL pressed) {
        [self mouseButtonChangeHandler:mouse button:aux_button state:pressed];
      };
    }
    ++mouseState->auxButtonCount;
    ++aux_button;
  }

  mouse.mouseInput.mouseMovedHandler = ^(GCMouseInput* mouseinput, float deltaX, float deltaY) {
    [self mouseMoveHandler:mouse deltaX:deltaX deltaY:deltaY];
  };
}

#pragma mark - GCMouse scroll wheelchangeHandler

- (void)wheelChangeHandler:(GCMouse*)mouse value:(float)value
{

  XBMC_Event newEvent = {};

  if (value > 0.0f)
    newEvent.button.button = XBMC_BUTTON_WHEELUP;
  else if (value < 0.0f)
    newEvent.button.button = XBMC_BUTTON_WHEELDOWN;
  else
    return;

  auto mouseState = [self getMouseState:mouse];
  if (mouseState == nil)
    return;

  newEvent.button.x = mouseState->x;
  newEvent.button.y = mouseState->y;

  std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
  if (appPort)
  {
    newEvent.type = XBMC_MOUSEBUTTONDOWN;
    appPort->OnEvent(newEvent);
    newEvent.type = XBMC_MOUSEBUTTONUP;
    appPort->OnEvent(newEvent);
  }
}

#pragma mark - GCMouse mouseMoveHandler

- (void)mouseMoveHandler:(GCMouse*)mouse deltaX:(float)deltaX deltaY:(float)deltaY
{
  XBMC_Event newEvent = {};

  auto mouseState = [self getMouseState:mouse];
  if (mouseState == nil)
    return;

  mouseState->x = mouseState->x - deltaX;
  mouseState->y = mouseState->y + deltaY;

  newEvent.type = XBMC_MOUSEMOTION;
  newEvent.button.x = mouseState->x;
  newEvent.button.y = mouseState->y;

  std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
  if (appPort)
    appPort->OnEvent(newEvent);
}

#pragma mark - GCMouse buttonChangeHandler

- (void)mouseButtonChangeHandler:(GCMouse*)mouse button:(int)buttonPressed state:(BOOL)state
{
  XBMC_Event newEvent = {};

  auto mouseState = [self getMouseState:mouse];
  if (mouseState == nil)
    return;

  newEvent.type = (state == YES) ? XBMC_MOUSEBUTTONDOWN : XBMC_MOUSEBUTTONUP;
  newEvent.button.x = mouseState->x;
  newEvent.button.y = mouseState->y;
  newEvent.button.button = buttonPressed;

  std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
  if (appPort)
    appPort->OnEvent(newEvent);
}

#pragma mark - utils

- (GCMouseState*)getMouseState:(GCMouse*)mouse
{
  for (int i = 0; i < MAX_MOUSE; i++)
  {
    if (mouseStateStruct[i].mouse == mouse)
    {
      return &mouseStateStruct[i];
    }
  }
  return nil;
}

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  [self addModeSwitchObserver];

  if (@available(iOS 14.0, tvOS 14.0, macOS 11.0, *))
  {
    auto mousearrtest = [GCMouse mice];
    for (GCMouse* mouse in mousearrtest)
      [self mouseConnection:mouse];
  }

  return self;
}

- (void)dealloc
{
  [self removeModeSwitchObserver];
}

@end
