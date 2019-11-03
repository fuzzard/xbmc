/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputGameController.h"

#include "utils/log.h"

#import "platform/darwin/tvos/XBMCController.h"
#import "platform/darwin/tvos/input/LibInputHandler.h"

#import <Foundation/Foundation.h>
#import <GameController/GameController.h>

@implementation TVOSLibInputGameController

- (void)gameControllerConnected:(NSNotification*)notification
{
  GCController* controller = (GCController*)notification.object;
  CLog::Log(LOGDEBUG, "Controller connected: {}", controller.vendorName.UTF8String);

// Array (tuple? vendorname:object?) required for upto 2 controllers
  m_gameController = controller;
  [self inputChangeHandler:controller];
}

- (void)gameControllerDisconnected:(NSNotification*)notification
{
  GCController* controller = (GCController*)notification.object;
  CLog::Log(LOGDEBUG, "Controller disconnected: {}", controller.vendorName.UTF8String);

// Array - check and remove correct device
  m_gameController = nil;
}

- (void)addObservers
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gameControllerConnected:)
                                               name:GCControllerDidConnectNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gameControllerDisconnected:)
                                               name:GCControllerDidDisconnectNotification
                                             object:nil];
}

- (void)inputChangeHandler:(GCController*)gameController
{
  // register block for input change detection
  GCExtendedGamepad* profile = gameController.extendedGamepad;
  profile.valueChangedHandler = ^(GCExtendedGamepad* gamepad, GCControllerElement* element) {
//    CGPoint position = CGPointMake(0, 0);

    // left trigger
    if (gamepad.leftTrigger == element && gamepad.leftTrigger.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: Left Trigger");

    // right trigger
    if (gamepad.rightTrigger == element && gamepad.rightTrigger.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: Right Trigger");

    // left shoulder button
    if (gamepad.leftShoulder == element && gamepad.leftShoulder.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: Left Shoulder");

    // right shoulder button
    if (gamepad.rightShoulder == element && gamepad.rightShoulder.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: Right Shoulder");

    // A button
    if (gamepad.buttonA == element && gamepad.buttonA.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: A Button");

    // B button
    if (gamepad.buttonB == element && gamepad.buttonB.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: B Button");

    // X button
    if (gamepad.buttonX == element && gamepad.buttonX.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: X Button");

    // Y button
    if (gamepad.buttonY == element && gamepad.buttonY.isPressed)
      CLog::Log(LOGDEBUG, "Controller button Press: Y Button");

    // d-pad
    if (gamepad.dpad == element)
    {
      if (gamepad.dpad.up.isPressed)
      CLog::Log(LOGDEBUG, "Controller D-Pad: Up");

      if (gamepad.dpad.down.isPressed)
      CLog::Log(LOGDEBUG, "Controller D-Pad: Down");

      if (gamepad.dpad.left.isPressed)
      CLog::Log(LOGDEBUG, "Controller D-Pad: Left");

      if (gamepad.dpad.right.isPressed)
      CLog::Log(LOGDEBUG, "Controller D-Pad: Right");
    }

    // left stick
    if (gamepad.leftThumbstick == element)
    {
      if (gamepad.leftThumbstick.up.isPressed)
        CLog::Log(LOGDEBUG, "Controller Left ThumbStick: Up value {}", gamepad.leftThumbstick.yAxis.value);

      if (gamepad.leftThumbstick.down.isPressed)
        CLog::Log(LOGDEBUG, "Controller Left ThumbStick: Down value {}", gamepad.leftThumbstick.yAxis.value);

      if (gamepad.leftThumbstick.left.isPressed)
        CLog::Log(LOGDEBUG, "Controller Left ThumbStick: Left value {}", gamepad.leftThumbstick.xAxis.value);

      if (gamepad.leftThumbstick.right.isPressed)
        CLog::Log(LOGDEBUG, "Controller Left ThumbStick: Right value {}", gamepad.leftThumbstick.xAxis.value);

//      position =
//          CGPointMake(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value);
    }

    // right stick
    if (gamepad.rightThumbstick == element)
    {
      if (gamepad.rightThumbstick.up.isPressed)
        CLog::Log(LOGDEBUG, "Controller Right ThumbStick: Up value {}", gamepad.rightThumbstick.yAxis.value);

      if (gamepad.rightThumbstick.down.isPressed)
        CLog::Log(LOGDEBUG, "Controller Right ThumbStick: Down value {}", gamepad.rightThumbstick.yAxis.value);

      if (gamepad.rightThumbstick.left.isPressed)
        CLog::Log(LOGDEBUG, "Controller Right ThumbStick: Left value {}", gamepad.rightThumbstick.xAxis.value);

      if (gamepad.rightThumbstick.right.isPressed)
        CLog::Log(LOGDEBUG, "Controller Right ThumbStick: Right value {}", gamepad.rightThumbstick.xAxis.value);

//      position =
//          CGPointMake(gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value);
    }
  };
}

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  [self addObservers];

  return self;
}

@end
