/*
 *  Copyright (C) 2020- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputHandler.h"

//#import "platform/darwin/input/LibInputHandlerKeyboard.h"
#import "platform/darwin/input/LibInputHandlerMouse.h"

@implementation DarwinLibInputHandler

@synthesize inputMouse;
//@synthesize inputKeyboard;

#pragma mark - internal key press methods

- (instancetype)init
{
  self = [super init];
  if (!self)
    return nil;

  //  inputKeyboard = [[OSXLibInputHandlerKeyboard alloc] init];
  inputMouse = [[DarwinLibInputHandlerMouse alloc] init];

  return self;
}

@end
