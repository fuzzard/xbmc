/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "windowing/XBMC_events.h"

#import <UIKit/UIKit.h>

typedef NS_ENUM(unsigned int, TVOSPlaybackState) {
  TVOS_PLAYBACK_STOPPED,
  TVOS_PLAYBACK_PAUSED,
  TVOS_PLAYBACK_PLAYING
};

typedef NS_ENUM(NSUInteger, UIPanGestureRecognizerDirection) {
  UIPanGestureRecognizerDirectionUndefined,
  UIPanGestureRecognizerDirectionUp,
  UIPanGestureRecognizerDirectionDown,
  UIPanGestureRecognizerDirectionLeft,
  UIPanGestureRecognizerDirectionRight
};

@class TVOSEAGLView;

@interface XBMCController : UIViewController <UIGestureRecognizerDelegate>
{
@private
  TVOSEAGLView* m_glView;
  // Touch handling
  CGSize m_screensize;
  CGPoint m_lastGesturePoint;
  CGFloat m_screenScale;
  int m_screenIdx;
  int m_currentClick;

  bool m_isPlayingBeforeInactive;
  UIBackgroundTaskIdentifier m_bgTask;
  TVOSPlaybackState m_playbackState;
  NSDictionary* m_nowPlayingInfo;
  bool m_nativeKeyboardActive;

  BOOL m_pause;
  BOOL m_appAlive;
  BOOL m_animating;
  BOOL m_disableIdleTimer;
  NSConditionLock* m_animationThreadLock;
  NSThread* m_animationThread;
  BOOL m_directionOverride;
  BOOL m_mimicAppleSiri;
  XBMCKey m_currentKey;
  BOOL m_clickResetPan;
  BOOL m_remoteIdleState;
  CGFloat m_remoteIdleTimeout;
  BOOL m_shouldRemoteIdle;
  BOOL m_RemoteOSDSwipes;
  unsigned long m_touchDirection;
  bool m_touchBeginSignaled;
  UIPanGestureRecognizerDirection m_direction;
}

@property(strong, nonatomic) NSTimer* pressAutoRepeatTimer;
@property(strong, nonatomic) NSTimer* remoteIdleTimer;

- (void)pauseAnimation;
- (void)resumeAnimation;
- (void)startAnimation;
- (void)stopAnimation;

- (void)enterBackground;
- (void)enterForeground;
- (void)becomeInactive;
- (void)setFramebuffer;
- (bool)presentFramebuffer;
- (CGSize)getScreenSize;
- (void)activateKeyboard:(UIView*)view;
- (void)deactivateKeyboard:(UIView*)view;
- (void)nativeKeyboardActive:(bool)active;

- (void)enableBackGroundTask;
- (void)disableBackGroundTask;

- (void)disableSystemSleep;
- (void)enableSystemSleep;
- (void)disableScreenSaver;
- (void)enableScreenSaver;
- (bool)resetSystemIdleTimer;
- (void)setSiriRemote:(BOOL)enable;
- (void)setRemoteIdleTimeout:(int)timeout;
- (void)setShouldRemoteIdle:(BOOL)idle;

- (NSArray<UIScreenMode*>*)availableScreenModes:(UIScreen*)screen;
- (UIScreenMode*)preferredScreenMode:(UIScreen*)screen;
- (bool)changeScreen:(unsigned int)screenIdx withMode:(UIScreenMode*)mode;

- (void)insertVideoView:(UIView*)view;
- (void)removeVideoView:(UIView*)view;
- (float)getDisplayRate;
- (void)displayRateSwitch:(float)refreshRate withDynamicRange:(int)dynamicRange;
- (void)displayRateReset;
- (EAGLContext*)getEAGLContextObj;
@end

extern XBMCController* g_xbmcController;
