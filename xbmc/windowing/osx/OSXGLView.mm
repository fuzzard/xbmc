/*
 *  Copyright (C) 2020 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "OSXGLView.h"

#include "system_gl.h"
#include "windowing/osx/WinEventsOSX.h"

#include "platform/darwin/osx/CocoaInterface.h"

@implementation OSXGLView

- (id)initWithFrame:(NSRect)frameRect
{
  NSOpenGLPixelFormatAttribute wattrs[] = {
      NSOpenGLPFADoubleBuffer,          NSOpenGLPFANoRecovery,
      NSOpenGLPFAAccelerated,           NSOpenGLPFAColorSize,
      (NSOpenGLPixelFormatAttribute)32, NSOpenGLPFAAlphaSize,
      (NSOpenGLPixelFormatAttribute)8,  NSOpenGLPFADepthSize,
      (NSOpenGLPixelFormatAttribute)24, (NSOpenGLPixelFormatAttribute)0};

  self = [super initWithFrame:frameRect];
  if (self)
  {
    m_pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:wattrs];
    m_glcontext = [[NSOpenGLContext alloc] initWithFormat:m_pixFmt shareContext:nil];

    GLint swapInterval = 1;
    [m_glcontext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

    m_trackingArea = nullptr;
    [self updateTrackingAreas];
  }
  return self;
}

- (void)dealloc
{
  [NSOpenGLContext clearCurrentContext];
  [m_glcontext clearDrawable];
}

- (void)drawRect:(NSRect)rect
{
  static BOOL firstRender = YES;
  if (firstRender)
  {
    [m_glcontext setView:self];
    firstRender = NO;

    // clear screen on first render
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0, 0, 0, 0);
  }
}

- (void)updateTrackingAreas
{
  // NSLog(@"updateTrackingAreas");
  if (m_trackingArea != nullptr)
    [self removeTrackingArea:m_trackingArea];

  const int opts =
      (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways);
  m_trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:opts
                                                  owner:self
                                               userInfo:nil];
  [self addTrackingArea:m_trackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  // NSLog(@"mouseEntered");
  Cocoa_HideMouse();
  [self displayIfNeeded];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
  // NSLog(@"mouseMoved");
  [self displayIfNeeded];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  // NSLog(@"mouseExited");
  //Cocoa_ShowMouse();
  [self displayIfNeeded];
}

- (NSOpenGLContext*)getGLContext
{
  return m_glcontext;
}
@end
