#pragma once

/*
 *      Copyright (C) 2010-2013 Team XBMC
 *      http://xbmc.org
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with XBMC; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */

#import <Cocoa/Cocoa.h>
/*
@interface OSXGLView : NSOpenGLView
{
@private
  NSOpenGLContext *context;
  NSOpenGLPixelFormat *m_pixFmt;
  NSTrackingArea *m_trackingArea;
  // The pixel dimensions of the CAEAGLLayer.
  GLint framebufferWidth;
  GLint framebufferHeight;
  // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
  GLuint defaultFramebuffer, colorRenderbuffer, depthRenderbuffer;
  // the shader program object
  GLuint program;
  //
  GLfloat rotz;

  BOOL animating;
  BOOL xbmcAlive;
  BOOL readyToRun;
  BOOL pause;
  NSConditionLock* animationThreadLock;
  NSThread* animationThread;
//  UIScreen* __weak currentScreen;

  BOOL framebufferResizeRequested;
}
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (readonly, nonatomic, getter=isXBMCAlive) BOOL xbmcAlive;
@property (readonly, nonatomic, getter=isReadyToRun) BOOL readyToRun;
@property (readonly, nonatomic, getter=isPause) BOOL pause;
@property(weak, readonly, getter=getCurrentScreen) NSScreen* currentScreen;
@property (readonly, getter=getCurrentGLContext) NSOpenGLContext *context;
@property BOOL framebufferResizeRequested;

- (id)initWithFrame:(NSRect)frameRect withScreen:(NSScreen *)screen;
- (void) pauseAnimation;
- (void) resumeAnimation;
- (void) startAnimation;
- (void) stopAnimation;
- (void) setFramebuffer;
- (bool) presentFramebuffer;
- (void) setScreen:(NSScreen *)screen withFrameBufferResize:(BOOL)resize;
- (CGFloat) getScreenScale:(NSScreen *)screen;
@end
*/

// old
@interface OSXGLView : NSOpenGLView
{
  NSOpenGLContext     *m_glcontext;
  NSOpenGLPixelFormat *m_pixFmt;
  NSTrackingArea      *m_trackingArea;
    BOOL pause;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (readonly, nonatomic, getter=isXBMCAlive) BOOL xbmcAlive;
@property (readonly, nonatomic, getter=isReadyToRun) BOOL readyToRun;
@property (readonly, nonatomic, getter=isPause) BOOL pause;
//@property(weak, readonly, getter=getCurrentScreen) UIScreen* currentScreen;
@property (readonly, getter=getCurrentNSContext) NSOpenGLContext *context;

- (id)initWithFrame: (NSRect)frameRect;
- (void)dealloc;
- (void) pauseAnimation;
- (void) resumeAnimation;
- (void) startAnimation;
- (void) stopAnimation;
- (void) setFramebuffer;
- (bool) presentFramebuffer;
- (NSOpenGLContext *)getGLContext;

@end

