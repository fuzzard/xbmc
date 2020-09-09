/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "LibInputHandlerMouse.h"

@implementation OSXLibInputHandlerMouse

#pragma mark - internal key press methods

//! @Todo: factor out siriremote customcontroller to a setting?
// allow to select multiple customcontrollers via setting list?
- (void)sendButtonPressed:(int)buttonId
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
