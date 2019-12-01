/*
 *  Copyright (C) 2019 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Foundation/Foundation.h>

@interface TVOSAudioManager : NSObject

- (void)handleAudioRouteChange:(NSNotification*)notification
- (void)handleAudioInterrupted:(NSNotification*)notification
- (void)handleMediaServicesReset:(NSNotification*)notification
- (void)audioRouteChanged;
- (void)registerAudioRouteNotifications;
- (void)unregisterAudioRouteNotifications;
- (instancetype)init;

@end
