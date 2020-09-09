/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

@class OSXLibInputHandlerKeyboard;
@class OSXLibInputHandlerMouse;

@interface OSXLibInputHandler : NSObject

@property(nonatomic, strong) OSXLibInputHandlerMouse* inputMouse;
@property(nonatomic, strong) OSXLibInputHandlerKeyboard* inputKeyboard;

//- (void)sendButtonPressed:(int)buttonId;
- (instancetype)init;

@end
