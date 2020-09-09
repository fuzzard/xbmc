/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputHandler.h"

#include "Application.h"
#include "ServiceBroker.h"
#include "guilib/GUIComponent.h"
#include "guilib/GUIWindowManager.h"
#include "input/InputManager.h"
#include "utils/log.h"

#import "platform/darwin/osx/input/LibInputHandlerKeyboard.h"
#import "platform/darwin/osx/input/LibInputHandlerMouse.h"

@implementation OSXLibInputHandler

@synthesize inputMouse;
@synthesize inputKeyboard;

#pragma mark - internal key press methods

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  inputKeyboard = [[OSXLibInputHandlerKeyboard alloc] init];
  inputMouse = [[OSXLibInputHandlerMouse alloc] init];

  return self;
}

@end
