/*
 *  Copyright (C) 2019- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

extern float const REPEATED_KEYPRESS_DELAY_S;
extern float const REPEATED_KEYPRESS_PAUSE_S;

@interface TVOSLibInputSettings : NSObject

@property(nonatomic) bool useSiriRemote;
@property(nonatomic) BOOL remoteIdleEnabled;
@property(nonatomic) int remoteIdleTimeout;

@end
