/*
 *  Copyright (C) 2010-2018 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#include "windowing/XBMC_events.h"

#import "platform/darwin/ios-common/DarwinEmbedNowPlayingInfoManager.h"
#import "platform/darwin/tvos/TVOSEAGLView.h"

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, UIPanGestureRecognizerDirection) {
  UIPanGestureRecognizerDirectionUndefined,
  UIPanGestureRecognizerDirectionUp,
  UIPanGestureRecognizerDirectionDown,
  UIPanGestureRecognizerDirectionLeft,
  UIPanGestureRecognizerDirectionRight
};

@class AVDisplayManager;
@class TVOSDisplayManager;
@class TVOSEAGLView;


@interface XBMCController : UIViewController <UIGestureRecognizerDelegate>
{
@private
  // Touch handling
  CGPoint m_lastGesturePoint;
  int m_screenIdx;
  int m_currentClick;

  bool m_isPlayingBeforeInactive;
  UIBackgroundTaskIdentifier m_bgTask;

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
@property (nonatomic, strong) DarwinEmbedNowPlayingInfoManager* MPNPInfoManager;
@property (nonatomic, strong) TVOSDisplayManager* displayManager;
@property (nonatomic, strong) TVOSEAGLView* glView;

- (void)pauseAnimation;
- (void)resumeAnimation;
- (void)startAnimation;
- (void)stopAnimation;

- (void)enterBackground;
- (void)enterForeground;
- (void)becomeInactive;
- (void)setFramebuffer;
- (bool)presentFramebuffer;
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

- (void)insertVideoView:(UIView*)view;
- (void)removeVideoView:(UIView*)view;
- (AVDisplayManager*)avDisplayManager __attribute__((availability(tvos, introduced = 11.2)));

- (EAGLContext*)getEAGLContextObj;

@end

extern XBMCController* g_xbmcController;
