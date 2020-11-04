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

#import "OSXGLView.h"

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

