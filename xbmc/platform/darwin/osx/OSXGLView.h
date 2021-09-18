#pragma once

/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import <Cocoa/Cocoa.h>

@interface OSXGLView : NSOpenGLView
{
  NSOpenGLContext* m_glcontext;
  NSOpenGLPixelFormat* m_pixFmt;
  NSTrackingArea* m_trackingArea;
  BOOL pause;
}

@property(readonly, nonatomic, getter=isAnimating) BOOL animating;
@property(readonly, nonatomic, getter=isXBMCAlive) BOOL xbmcAlive;
@property(readonly, nonatomic, getter=isReadyToRun) BOOL readyToRun;
@property(readonly, nonatomic, getter=isPause) BOOL pause;
//@property(weak, readonly, getter=getCurrentScreen) UIScreen* currentScreen;
@property(readonly, getter=getCurrentNSContext) NSOpenGLContext* context;

- (id)initWithFrame:(NSRect)frameRect;
- (void)dealloc;
- (void)pauseAnimation;
- (void)resumeAnimation;
- (void)startAnimation;
- (void)stopAnimation;
- (void)setFramebuffer;
- (bool)presentFramebuffer;
- (NSOpenGLContext*)getGLContext;

@end
