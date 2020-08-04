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
/*
//--------------------------------------------------------------
@interface OSXGLView (PrivateMethods)
- (void) setContext:(NSOpenGLContext *)newContext;
- (void) createFramebuffer;
- (void) deleteFramebuffer;
- (void) runDisplayLink;
@end

@implementation OSXGLView
@synthesize animating;
@synthesize xbmcAlive;
@synthesize readyToRun;
@synthesize pause;
@synthesize currentScreen;
@synthesize framebufferResizeRequested;
@synthesize context;

//--------------------------------------------------------------
- (void) resizeFrameBuffer
{
  NSRect frame = [[NSScreen mainScreen] frame];
  CAOpenGLLayer *glLayer = (CAOpenGLLayer *)[self layer];
  
  //resize the layer - ios will delay this
  //and call layoutSubviews when its done with resizing
  //so the real framebuffer resize is done there then ...
  if(framebufferWidth != frame.size.width ||
     framebufferHeight != frame.size.height )
  {
    framebufferResizeRequested = TRUE;
    [glLayer setFrame:frame];
  }
}

- (void)layout
{
  if(framebufferResizeRequested)
  {
    framebufferResizeRequested = FALSE;
    [self deleteFramebuffer];
    [self createFramebuffer];
    [self setFramebuffer];
  }
}

- (void) setScreen:(NSScreen *)screen withFrameBufferResize:(BOOL)resize
{
  currentScreen = screen;

  if(resize)
  {
    [self resizeFrameBuffer];
  }
}

//--------------------------------------------------------------
- (id)initWithFrame:(NSRect)frameRect withScreen:(NSScreen *)screen
{
  framebufferResizeRequested = FALSE;
  if ((self = [super initWithFrame:frameRect]))
  {
    // Get the layer
    CAOpenGLLayer *glLayer = (CAOpenGLLayer *)self.layer;
    //set screen, handlescreenscale
    //and set frame size
    [self setScreen:screen withFrameBufferResize:FALSE];

    glLayer.opaque = TRUE;

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
      self.context = [[NSOpenGLContext alloc] initWithFormat:m_pixFmt shareContext:nil];
    }

    GLint swapInterval = 1;
    [context setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    [context makeCurrentContext];

    [self updateTrackingAreas];

    if (!self.context)
      CLog::Log(LOGERROR, "Failed to create GL context");

    animating = FALSE;
    xbmcAlive = FALSE;
    pause = FALSE;
    [self setContext:context];
    [self createFramebuffer];
    [self setFramebuffer];
  }

  return self;
}

//--------------------------------------------------------------
- (void) dealloc
{
  [self deleteFramebuffer];
  [NSOpenGLContext clearCurrentContext];
  [context clearDrawable];
}

//--------------------------------------------------------------
- (NSOpenGLContext *)context
{
  return context;
}
//--------------------------------------------------------------
- (void)setContext:(NSOpenGLContext *)newContext
{
  if (context != newContext)
  {
    [self deleteFramebuffer];
    context = newContext;
    [NSOpenGLContext clearCurrentContext];
  }
}

//--------------------------------------------------------------
- (void)createFramebuffer
{
  if (context && !defaultFramebuffer)
  {
    [context makeCurrentContext];

    glGenFramebuffers(1, &defaultFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
      
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, framebufferWidth, framebufferHeight);

    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, framebufferWidth, framebufferHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
      CLog::Log(LOGERROR, "Failed to make complete framebuffer object {}", glCheckFramebufferStatus(GL_FRAMEBUFFER));
  }
}
//--------------------------------------------------------------
- (void) deleteFramebuffer
{
  if (context && !pause)
  {
    [context makeCurrentContext];

    if (defaultFramebuffer)
    {
      glDeleteFramebuffers(1, &defaultFramebuffer);
      defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
      glDeleteRenderbuffers(1, &colorRenderbuffer);
      colorRenderbuffer = 0;
    }

    if (depthRenderbuffer)
    {
      glDeleteRenderbuffers(1, &depthRenderbuffer);
      depthRenderbuffer = 0;
    }
  }
}
//--------------------------------------------------------------
- (void) setFramebuffer
{
  if (context && !pause)
  {
    if ([NSOpenGLContext currentContext] != context)
      [context makeCurrentContext];

    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);

    if(framebufferHeight > framebufferWidth) {
      glViewport(0, 0, framebufferHeight, framebufferWidth);
      glScissor(0, 0, framebufferHeight, framebufferWidth);
    }
    else
    {
      glViewport(0, 0, framebufferWidth, framebufferHeight);
      glScissor(0, 0, framebufferWidth, framebufferHeight);
    }
  }
}
//--------------------------------------------------------------
- (bool) presentFramebuffer
{
  bool success = FALSE;

  if (context && !pause)
  {
    if ([NSOpenGLContext currentContext] != context)
      [context makeCurrentContext];

    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    //success = [context presentRenderbuffer:GL_RENDERBUFFER];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  }

  return success;
}
//--------------------------------------------------------------
- (void) pauseAnimation
{
  pause = TRUE;
  std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
  if (appPort)
    appPort->SetRenderGUI(false);
}
//--------------------------------------------------------------
- (void) resumeAnimation
{
  pause = FALSE;
  std::shared_ptr<CAppInboundProtocol> appPort = CServiceBroker::GetAppPort();
  if (appPort)
    appPort->SetRenderGUI(true);
}
//--------------------------------------------------------------
- (void) startAnimation
{
    if (!animating && context)
    {
        animating = TRUE;

    // kick off an animation thread
    animationThreadLock = [[NSConditionLock alloc] initWithCondition: FALSE];
    animationThread = [[NSThread alloc] initWithTarget:self
      selector:@selector(runAnimation:)
      object:animationThreadLock];
    [animationThread start];
    }
}
//--------------------------------------------------------------
- (void) stopAnimation
{
    if (animating && context)
    {
        animating = FALSE;
    xbmcAlive = FALSE;
    if (!g_application.m_bStop)
    {
      KODI::MESSAGING::CApplicationMessenger::GetInstance().PostMsg(TMSG_QUIT);
    }

    //CAnnounceReceiver::GetInstance()->DeInitialize();

    // wait for animation thread to die
    if ([animationThread isFinished] == NO)
      [animationThreadLock lockWhenCondition:TRUE];
    }
}
//--------------------------------------------------------------
- (void) runAnimation:(id) arg
{
  @autoreleasepool
  {
    [[NSThread currentThread] setName:@"XBMC_Run"];

    // set up some xbmc specific relationships
    readyToRun = true;

    // signal we are alive
    NSConditionLock* myLock = arg;
    [myLock lock];

    CAppParamParser appParamParser;
#ifdef _DEBUG
    appParamParser.m_logLevel = LOG_LEVEL_DEBUG;
#else
    appParamParser.m_logLevel = LOG_LEVEL_NORMAL;
#endif

    // Prevent child processes from becoming zombies on exit if not waited upon. See also Util::Command
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_flags = SA_NOCLDWAIT;
    sa.sa_handler = SIG_IGN;
    sigaction(SIGCHLD, &sa, NULL);

    setlocale(LC_NUMERIC, "C");

    g_application.Preflight();
    if (!g_application.Create(appParamParser))
    {
      readyToRun = false;
      CLog::Log(LOGERROR, "{} - Unable to create application", __PRETTY_FUNCTION__);
    }

    if (!g_application.CreateGUI())
    {
      readyToRun = false;
      CLog::Log(LOGERROR, "{} - Unable to create GUI", __PRETTY_FUNCTION__);
    }

    if (!g_application.Initialize())
    {
      readyToRun = false;
      CLog::Log(LOGERROR, "{} - Unable to initialize application", __PRETTY_FUNCTION__);
    }

    if (readyToRun)
    {
      CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_startFullScreen = true;
      CServiceBroker::GetSettingsComponent()->GetAdvancedSettings()->m_canWindowed = false;
      xbmcAlive = TRUE;

      try
      {
        @autoreleasepool
        {
          g_application.Run(CAppParamParser());
        }
      }
      catch (...)
      {
        CLog::Log(LOGERROR, "{} - Exception caught on main loop. Exiting", __PRETTY_FUNCTION__);
      }
    }

    // signal we are dead
    [myLock unlockWithCondition:TRUE];


    //[g_xbmcController enableScreenSaver];
    //[g_xbmcController enableSystemSleep];
    exit(0);
  }
}
//--------------------------------------------------------------
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
@end
*/
// OLD
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

