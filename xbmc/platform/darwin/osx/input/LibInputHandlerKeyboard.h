/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface OSXLibInputHandlerKeyboard : NSObject

- (void)sendButtonPressed:(NSEvent *)theEvent;
- (void)sendButtonReleased:(NSEvent *)theEvent;
- (instancetype)init;

@end
