/*
 *  Copyright (C) 2019 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

@class CADisplayLink;
class CWinSystemTVOS;

@interface TVOSDisplayManager : NSObject
{
  CADisplayLink* m_displayLink;
  CWinSystemTVOS* m_winSystem;
  float m_displayRate;
}

- (float)getDisplayRate;
- (void)displayLinkTick:(CADisplayLink*)sender;
- (void)displayRateSwitch:(float)refreshRate withDynamicRange:(int)dynamicRange;
- (void)displayRateReset;
- (void)removeModeSwitchObserver;
- (void)addModeSwitchObserver;
- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context;
- (const char*)stringFromDynamicRange:(int)dynamicRange;
- (instancetype)init;
@end
