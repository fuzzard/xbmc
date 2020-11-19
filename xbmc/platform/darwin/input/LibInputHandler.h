/*
 *  Copyright (C) 2020- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

//@class DarwinLibInputHandlerKeyboard;
@class DarwinLibInputHandlerMouse;

@interface DarwinLibInputHandler : NSObject

@property(nonatomic, strong) DarwinLibInputHandlerMouse* inputMouse;
//@property(nonatomic, strong) OSXLibInputHandlerKeyboard* inputKeyboard;

- (instancetype)init;

@end
