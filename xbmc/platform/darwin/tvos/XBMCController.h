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

@class AVDisplayManager;
@class TVOSLibInputHandler;
@class TVOSDisplayManager;


@interface XBMCController : UIViewController
{
@private
  bool m_isPlayingBeforeInactive;
  UIBackgroundTaskIdentifier m_bgTask;
  bool m_nativeKeyboardActive;
  BOOL m_pause;
  BOOL m_animating;
  NSConditionLock* m_animationThreadLock;
  NSThread* m_animationThread;
}

@property(nonatomic) BOOL appAlive;
@property(nonatomic, strong) DarwinEmbedNowPlayingInfoManager* MPNPInfoManager;
@property(nonatomic, strong) TVOSDisplayManager* displayManager;
@property(nonatomic, strong) TVOSEAGLView* glView;
@property(nonatomic, strong) TVOSLibInputHandler* inputHandler;

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

- (void)insertVideoView:(UIView*)view;
- (void)removeVideoView:(UIView*)view;
- (AVDisplayManager*)avDisplayManager __attribute__((availability(tvos, introduced = 11.2)));

- (EAGLContext*)getEAGLContextObj;

@end

extern XBMCController* g_xbmcController;
