/*
 *  Copyright (C) 2021- Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#import "OSXGLView.h"

#include "system_gl.h"
#include "platform/darwin/osx/CocoaInterface.h"
#include "utils/log.h"
#include "AppInboundProtocol.h"
#include "ServiceBroker.h"
#include "messaging/ApplicationMessenger.h"
#include "Application.h"
#include "AppParamParser.h"
#include "settings/SettingsComponent.h"
#include "settings/AdvancedSettings.h"

@implementation OSXGLView

- (id)initWithFrame: (NSRect)frameRect
{
  NSOpenGLPixelFormatAttribute wattrs[] =
  {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFAWindow,
    NSOpenGLPFANoRecovery,
    NSOpenGLPFAAccelerated,
    NSOpenGLPFAColorSize,           (NSOpenGLPixelFormatAttribute)32,
    NSOpenGLPFAAlphaSize,           (NSOpenGLPixelFormatAttribute)8,
    NSOpenGLPFADepthSize,           (NSOpenGLPixelFormatAttribute)24,
    (NSOpenGLPixelFormatAttribute) 0
  };

  self = [super initWithFrame: frameRect];
  if (self)
  {
    m_pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:wattrs];
    m_glcontext = [[NSOpenGLContext alloc] initWithFormat:m_pixFmt shareContext:nil];
  }

  [self updateTrackingAreas];

  GLint swapInterval = 1;
  [m_glcontext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
  [m_glcontext makeCurrentContext];

  return self;
}

- (void)dealloc
{
  //NSLog(@"OSXGLView dealoc");
  [NSOpenGLContext clearCurrentContext];
  [m_glcontext clearDrawable];
}

- (void)drawRect:(NSRect)rect
{
  static BOOL firstRender = YES;
  if (firstRender)
  {
    //NSLog(@"OSXGLView drawRect setView");
    [m_glcontext setView:self];
    firstRender = NO;

    // clear screen on first render
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0, 0, 0, 0);

    [m_glcontext update];
  }
}

-(void)updateTrackingAreas
{
  //NSLog(@"updateTrackingAreas");
  if (m_trackingArea != nil)
  {
    [self removeTrackingArea:m_trackingArea];
  }

  const int opts = (NSTrackingMouseEnteredAndExited |
                    NSTrackingMouseMoved |
                    NSTrackingActiveAlways);
  m_trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
  [self addTrackingArea:m_trackingArea];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  //NSLog(@"mouseEntered");
  Cocoa_HideMouse();
  [self displayIfNeeded];
}

- (void)mouseMoved:(NSEvent*)theEvent
{
  //NSLog(@"mouseMoved");
  [self displayIfNeeded];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  //NSLog(@"mouseExited");
  Cocoa_ShowMouse();
  [self displayIfNeeded];
}

- (NSOpenGLContext *)getGLContext
{
  return m_glcontext;
}
@end
